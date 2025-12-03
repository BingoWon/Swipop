/**
 * DeepSeek AI Chat Proxy
 * 
 * Securely proxies requests to DeepSeek API with:
 * - User authentication via Supabase
 * - API key stored in environment variables
 * - SSE streaming support
 * - Thinking mode support (reasoning_content)
 */

const DEEPSEEK_URL = "https://api.deepseek.com/chat/completions";

Deno.serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: corsHeaders(),
    });
  }

  // Verify auth
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return jsonError("Unauthorized", 401);
  }

  const { createClient } = await import("https://esm.sh/@supabase/supabase-js@2");
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const token = authHeader.slice(7);
  const { data: { user }, error: authError } = await supabase.auth.getUser(token);
  if (authError || !user) {
    return jsonError("Invalid token", 401);
  }

  // Parse request
  let body: {
    model: string;
    messages: Message[];
    tools?: Tool[];
    thinking?: { type: string };
  };

  try {
    body = await req.json();
  } catch {
    return jsonError("Invalid JSON", 400);
  }

  const { model, messages, tools, thinking } = body;
  if (!model || !messages) {
    return jsonError("Missing model or messages", 400);
  }

  // Get API key from environment
  const apiKey = Deno.env.get("DEEPSEEK_API_KEY");
  if (!apiKey) {
    return jsonError("API key not configured", 500);
  }

  // Build DeepSeek request
  const deepseekBody: Record<string, unknown> = {
    model,
    messages,
    stream: true,
    stream_options: { include_usage: true },
  };

  if (tools?.length) {
    deepseekBody.tools = tools;
  }

  // Enable thinking mode for deepseek-reasoner or explicit thinking param
  if (model === "deepseek-reasoner" || thinking?.type === "enabled") {
    deepseekBody.thinking = { type: "enabled" };
  }

  // Call DeepSeek API
  const response = await fetch(DEEPSEEK_URL, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(deepseekBody),
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error(`DeepSeek API error: ${response.status} - ${errorText}`);
    return jsonError(`DeepSeek API error: ${response.status}`, response.status);
  }

  // Stream SSE response
  return streamResponse(response);
});

// Types
interface Message {
  role: string;
  content?: string | null;
  reasoning_content?: string | null;
  tool_calls?: ToolCall[];
  tool_call_id?: string;
}

interface Tool {
  type: string;
  function: {
    name: string;
    description: string;
    parameters: Record<string, unknown>;
  };
}

interface ToolCall {
  id: string;
  type: string;
  function: {
    name: string;
    arguments: string;
  };
}

function corsHeaders(): HeadersInit {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type",
  };
}

function streamResponse(upstreamResponse: Response): Response {
  const stream = new ReadableStream({
    async start(controller) {
      const reader = upstreamResponse.body!.getReader();

      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          controller.enqueue(value);
        }
        controller.close();
      } catch (err) {
        console.error("Stream error:", err);
        controller.error(err);
      }
    },
  });

  return new Response(stream, {
    headers: {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      "Connection": "keep-alive",
      ...corsHeaders(),
    },
  });
}

function jsonError(message: string, status: number): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders(),
    },
  });
}
