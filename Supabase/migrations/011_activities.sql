-- ============================================
-- Activities (Notifications) System
-- Version: 011
-- ============================================

-- Activities table for storing user notifications
CREATE TABLE IF NOT EXISTS public.activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,  -- Notification recipient
    actor_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE, -- User who triggered the action
    type TEXT NOT NULL CHECK (type IN ('like', 'comment', 'follow', 'collect')),
    work_id UUID REFERENCES public.works(id) ON DELETE CASCADE,
    comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_activities_user_id ON public.activities(user_id);
CREATE INDEX IF NOT EXISTS idx_activities_created_at ON public.activities(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activities_is_read ON public.activities(user_id, is_read) WHERE NOT is_read;

-- RLS Policies
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

-- Users can only read their own activities
CREATE POLICY "Users can read own activities"
    ON public.activities FOR SELECT
    USING (auth.uid() = user_id);

-- Users can update (mark as read) their own activities
CREATE POLICY "Users can update own activities"
    ON public.activities FOR UPDATE
    USING (auth.uid() = user_id);

-- System inserts activities via trigger (SECURITY DEFINER)
CREATE POLICY "System can insert activities"
    ON public.activities FOR INSERT
    WITH CHECK (true);

-- ============================================
-- Trigger Functions
-- ============================================

-- Create activity on like
CREATE OR REPLACE FUNCTION create_like_activity()
RETURNS TRIGGER AS $$
DECLARE
    work_owner_id UUID;
BEGIN
    -- Get work owner
    SELECT user_id INTO work_owner_id FROM public.works WHERE id = NEW.work_id;
    
    -- Don't notify if user likes their own work
    IF work_owner_id IS NOT NULL AND work_owner_id != NEW.user_id THEN
        INSERT INTO public.activities (user_id, actor_id, type, work_id)
        VALUES (work_owner_id, NEW.user_id, 'like', NEW.work_id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create activity on collect
CREATE OR REPLACE FUNCTION create_collect_activity()
RETURNS TRIGGER AS $$
DECLARE
    work_owner_id UUID;
BEGIN
    SELECT user_id INTO work_owner_id FROM public.works WHERE id = NEW.work_id;
    
    IF work_owner_id IS NOT NULL AND work_owner_id != NEW.user_id THEN
        INSERT INTO public.activities (user_id, actor_id, type, work_id)
        VALUES (work_owner_id, NEW.user_id, 'collect', NEW.work_id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create activity on comment
CREATE OR REPLACE FUNCTION create_comment_activity()
RETURNS TRIGGER AS $$
DECLARE
    work_owner_id UUID;
BEGIN
    SELECT user_id INTO work_owner_id FROM public.works WHERE id = NEW.work_id;
    
    IF work_owner_id IS NOT NULL AND work_owner_id != NEW.user_id THEN
        INSERT INTO public.activities (user_id, actor_id, type, work_id, comment_id)
        VALUES (work_owner_id, NEW.user_id, 'comment', NEW.work_id, NEW.id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create activity on follow
CREATE OR REPLACE FUNCTION create_follow_activity()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.activities (user_id, actor_id, type)
    VALUES (NEW.following_id, NEW.follower_id, 'follow');
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Triggers
-- ============================================

DROP TRIGGER IF EXISTS on_like_create_activity ON public.likes;
CREATE TRIGGER on_like_create_activity
    AFTER INSERT ON public.likes
    FOR EACH ROW EXECUTE FUNCTION create_like_activity();

DROP TRIGGER IF EXISTS on_collect_create_activity ON public.collections;
CREATE TRIGGER on_collect_create_activity
    AFTER INSERT ON public.collections
    FOR EACH ROW EXECUTE FUNCTION create_collect_activity();

DROP TRIGGER IF EXISTS on_comment_create_activity ON public.comments;
CREATE TRIGGER on_comment_create_activity
    AFTER INSERT ON public.comments
    FOR EACH ROW EXECUTE FUNCTION create_comment_activity();

DROP TRIGGER IF EXISTS on_follow_create_activity ON public.follows;
CREATE TRIGGER on_follow_create_activity
    AFTER INSERT ON public.follows
    FOR EACH ROW EXECUTE FUNCTION create_follow_activity();

