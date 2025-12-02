import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SILICONFLOW_URL = "https://api.siliconflow.cn/v1/chat/completions";
const MAX_RETRIES = 3;
const FATAL_ERRORS = [401, 402, 403];
const RETRY_ERRORS = [429];

Deno.serve(async (req) => {
  // CORS
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Authorization, Content-Type",
      },
    });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return jsonError("Unauthorized", 401);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  // Verify user
  const token = authHeader.slice(7);
  const { data: { user }, error: authError } = await supabase.auth.getUser(token);
  if (authError || !user) {
    return jsonError("Invalid token", 401);
  }

  // Parse request
  let body: { model: string; messages: unknown[]; tools?: unknown[] };
  try {
    body = await req.json();
  } catch {
    return jsonError("Invalid JSON", 400);
  }

  const { model, messages, tools } = body;
  if (!model || !messages) {
    return jsonError("Missing model or messages", 400);
  }

  // Retry loop
  let lastError: { code: number; message: string } | null = null;
  const triedKeyIds: string[] = [];

  for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
    // Get random key using PostgreSQL RANDOM()
    let query = supabase.rpc("get_random_api_key", { excluded_ids: triedKeyIds });
    const { data: keyData, error: keyError } = await query;

    if (keyError || !keyData) {
      // Fallback: direct query if RPC doesn't exist
      let fallbackQuery = supabase
        .from("api_keys")
        .select("id, key")
        .limit(100);

      if (triedKeyIds.length > 0) {
        fallbackQuery = fallbackQuery.not("id", "in", `(${triedKeyIds.map(k => `'${k}'`).join(",")})`);
      }

      const { data: keys } = await fallbackQuery;
      if (!keys?.length) {
        return jsonError("No API keys available", 503);
      }

      // Random selection in application layer
      const randomKey = keys[Math.floor(Math.random() * keys.length)];
      triedKeyIds.push(randomKey.id);

      const result = await tryApiCall(randomKey.key, model, messages, tools);
      if (result.success) {
        return streamResponse(result.response!, user.id, model, messages, supabase);
      }

      lastError = { code: result.status!, message: result.error! };
      if (FATAL_ERRORS.includes(result.status!)) {
        await supabase.from("api_keys").delete().eq("id", randomKey.id);
      }
      if (!FATAL_ERRORS.includes(result.status!) && !RETRY_ERRORS.includes(result.status!)) {
        break;
      }
      continue;
    }

    triedKeyIds.push(keyData.id);

    const result = await tryApiCall(keyData.key, model, messages, tools);
    if (result.success) {
      return streamResponse(result.response!, user.id, model, messages, supabase);
    }

    lastError = { code: result.status!, message: result.error! };
    if (FATAL_ERRORS.includes(result.status!)) {
      await supabase.from("api_keys").delete().eq("id", keyData.id);
      continue;
    }
    if (RETRY_ERRORS.includes(result.status!)) {
      continue;
    }
    break;
  }

  // Log failure
  await supabase.from("chat_sessions").insert({
    user_id: user.id,
    model,
    messages,
    error_code: lastError?.code,
  });

  return jsonError(lastError?.message || "All API keys exhausted", 503);
});

async function tryApiCall(
  apiKey: string,
  model: string,
  messages: unknown[],
  tools?: unknown[]
): Promise<{ success: boolean; response?: Response; status?: number; error?: string }> {
  const response = await fetch(SILICONFLOW_URL, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ model, messages, tools, stream: true }),
  });

  if (response.ok) {
    return { success: true, response };
  }

  return {
    success: false,
    status: response.status,
    error: await response.text(),
  };
}

function streamResponse(
  upstreamResponse: Response,
  userId: string,
  model: string,
  messages: unknown[],
  supabase: ReturnType<typeof createClient>
): Response {
  const responseText: string[] = [];

  const stream = new ReadableStream({
    async start(controller) {
      const reader = upstreamResponse.body!.getReader();
      const decoder = new TextDecoder();

      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;

          const chunk = decoder.decode(value, { stream: true });
          controller.enqueue(new TextEncoder().encode(chunk));

          // Extract content for logging
          for (const line of chunk.split("\n")) {
            if (line.startsWith("data: ") && line !== "data: [DONE]") {
              try {
                const json = JSON.parse(line.slice(6));
                const content = json.choices?.[0]?.delta?.content;
                if (content) responseText.push(content);
              } catch { /* ignore */ }
            }
          }
        }

        await supabase.from("chat_sessions").insert({
          user_id: userId,
          model,
          messages,
          response: responseText.join(""),
        });

        controller.close();
      } catch (err) {
        controller.error(err);
      }
    },
  });

  return new Response(stream, {
    headers: {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      "Connection": "keep-alive",
      "Access-Control-Allow-Origin": "*",
    },
  });
}

function jsonError(message: string, status: number): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}
