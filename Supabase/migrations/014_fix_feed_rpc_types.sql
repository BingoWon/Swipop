-- ============================================
-- Fix Feed RPC Type Mismatch
-- Version: 014
-- ============================================
-- Error: "structure of query does not match function result type"
-- Cause: thumbnail_aspect_ratio is REAL in table but DOUBLE PRECISION in function

-- Drop and recreate with explicit type casting
DROP FUNCTION IF EXISTS get_feed_with_interactions;

CREATE OR REPLACE FUNCTION get_feed_with_interactions(
    p_user_id UUID DEFAULT NULL,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    title TEXT,
    description TEXT,
    html_content TEXT,
    css_content TEXT,
    js_content TEXT,
    thumbnail_url TEXT,
    thumbnail_aspect_ratio REAL,  -- Match works table type
    tags TEXT[],
    chat_messages JSONB,
    is_published BOOLEAN,
    view_count INTEGER,
    like_count INTEGER,
    collect_count INTEGER,
    comment_count INTEGER,
    share_count INTEGER,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    is_liked BOOLEAN,
    is_collected BOOLEAN,
    creator_id UUID,
    creator_username TEXT,
    creator_display_name TEXT,
    creator_avatar_url TEXT,
    creator_bio TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        w.id,
        w.user_id,
        w.title,
        w.description,
        w.html_content,
        w.css_content,
        w.js_content,
        w.thumbnail_url,
        w.thumbnail_aspect_ratio,
        w.tags,
        w.chat_messages,
        w.is_published,
        w.view_count,
        w.like_count,
        w.collect_count,
        w.comment_count,
        w.share_count,
        w.created_at,
        w.updated_at,
        COALESCE(
            p_user_id IS NOT NULL AND EXISTS(
                SELECT 1 FROM likes l WHERE l.work_id = w.id AND l.user_id = p_user_id
            ),
            FALSE
        ) AS is_liked,
        COALESCE(
            p_user_id IS NOT NULL AND EXISTS(
                SELECT 1 FROM collections c WHERE c.work_id = w.id AND c.user_id = p_user_id
            ),
            FALSE
        ) AS is_collected,
        u.id AS creator_id,
        u.username AS creator_username,
        u.display_name AS creator_display_name,
        u.avatar_url AS creator_avatar_url,
        u.bio AS creator_bio
    FROM works w
    LEFT JOIN users u ON u.id = w.user_id
    WHERE w.is_published = true
    ORDER BY w.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;

GRANT EXECUTE ON FUNCTION get_feed_with_interactions TO authenticated;
GRANT EXECUTE ON FUNCTION get_feed_with_interactions TO anon;

