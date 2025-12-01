-- ============================================
-- Row Level Security Policies
-- Version: 002
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.works ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

-- USERS policies
CREATE POLICY "Users are viewable by everyone"
    ON public.users FOR SELECT
    USING (true);

CREATE POLICY "Users can update own profile"
    ON public.users FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON public.users FOR INSERT
    WITH CHECK (auth.uid() = id);

-- WORKS policies
CREATE POLICY "Published works are viewable by everyone"
    ON public.works FOR SELECT
    USING (is_published = true OR auth.uid() = user_id);

CREATE POLICY "Users can create own works"
    ON public.works FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own works"
    ON public.works FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own works"
    ON public.works FOR DELETE
    USING (auth.uid() = user_id);

-- LIKES policies
CREATE POLICY "Likes are viewable by everyone"
    ON public.likes FOR SELECT
    USING (true);

CREATE POLICY "Users can create own likes"
    ON public.likes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own likes"
    ON public.likes FOR DELETE
    USING (auth.uid() = user_id);

-- COLLECTIONS policies
CREATE POLICY "Users can view own collections"
    ON public.collections FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create own collections"
    ON public.collections FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own collections"
    ON public.collections FOR DELETE
    USING (auth.uid() = user_id);

-- COMMENTS policies
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

-- FOLLOWS policies
CREATE POLICY "Follows are viewable by everyone"
    ON public.follows FOR SELECT
    USING (true);

CREATE POLICY "Users can create own follows"
    ON public.follows FOR INSERT
    WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can delete own follows"
    ON public.follows FOR DELETE
    USING (auth.uid() = follower_id);

