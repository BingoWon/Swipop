-- ============================================
-- Row Level Security Policies
-- Current state as of 2024
-- ============================================

-- ===================
-- ENABLE RLS
-- ===================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.works ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;

-- ===================
-- USERS
-- ===================
CREATE POLICY "Users are viewable by everyone"
    ON public.users FOR SELECT
    USING (true);

CREATE POLICY "Users can update own profile"
    ON public.users FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON public.users FOR INSERT
    WITH CHECK (auth.uid() = id);

-- ===================
-- WORKS
-- ===================
-- View: Published works visible to all, drafts only to owner
CREATE POLICY "Users can view own works"
    ON public.works FOR SELECT
    USING (user_id = auth.uid() OR is_published = true);

CREATE POLICY "Users can insert own works"
    ON public.works FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own works"
    ON public.works FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "Users can delete own works"
    ON public.works FOR DELETE
    USING (auth.uid() = user_id);

-- ===================
-- LIKES
-- ===================
CREATE POLICY "Likes are viewable by everyone"
    ON public.likes FOR SELECT
    USING (true);

CREATE POLICY "Users can create own likes"
    ON public.likes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own likes"
    ON public.likes FOR DELETE
    USING (auth.uid() = user_id);

-- ===================
-- COLLECTIONS
-- ===================
-- Collections are private - only visible to owner
CREATE POLICY "Users can view own collections"
    ON public.collections FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create own collections"
    ON public.collections FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own collections"
    ON public.collections FOR DELETE
    USING (auth.uid() = user_id);

-- ===================
-- COMMENTS
-- ===================
CREATE POLICY "Comments are viewable by everyone"
    ON public.comments FOR SELECT
    USING (true);

CREATE POLICY "Users can create comments"
    ON public.comments FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own comments"
    ON public.comments FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments"
    ON public.comments FOR DELETE
    USING (auth.uid() = user_id);

-- ===================
-- FOLLOWS
-- ===================
CREATE POLICY "Follows are viewable by everyone"
    ON public.follows FOR SELECT
    USING (true);

CREATE POLICY "Users can create own follows"
    ON public.follows FOR INSERT
    WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can delete own follows"
    ON public.follows FOR DELETE
    USING (auth.uid() = follower_id);

-- ===================
-- ACTIVITIES
-- ===================
-- Users can only see their own notifications
CREATE POLICY "Users can read own activities"
    ON public.activities FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update own activities"
    ON public.activities FOR UPDATE
    USING (auth.uid() = user_id);

-- System inserts via SECURITY DEFINER triggers
CREATE POLICY "System can insert activities"
    ON public.activities FOR INSERT
    WITH CHECK (true);

-- ===================
-- API KEYS
-- ===================
-- No policies - service role only (Edge Functions use service role key)

-- ===================
-- CHAT SESSIONS
-- ===================
-- Users can only view their own sessions
CREATE POLICY "Users can view own chat sessions"
    ON public.chat_sessions FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- Insert via service role only (Edge Function)

