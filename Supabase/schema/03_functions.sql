-- ============================================
-- PostgreSQL Functions
-- Current state as of 2024
-- ============================================

-- ===================
-- UTILITY FUNCTIONS
-- ===================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ===================
-- USERNAME GENERATION
-- ===================

-- Generate unique username from display_name
-- Rules: lowercase, spaces→underscores, alphanumeric only, collision handling
CREATE OR REPLACE FUNCTION generate_username(display_name TEXT)
RETURNS TEXT AS $$
DECLARE
    base_username TEXT;
    final_username TEXT;
    counter INTEGER := 0;
BEGIN
    -- Generate base: lowercase, replace spaces, keep alphanumeric + underscore
    base_username := LOWER(COALESCE(display_name, 'user'));
    base_username := REGEXP_REPLACE(base_username, '\s+', '_', 'g');
    base_username := REGEXP_REPLACE(base_username, '[^a-z0-9_]', '', 'g');
    
    -- Ensure minimum length
    IF LENGTH(base_username) < 3 THEN
        base_username := 'user_' || base_username;
    END IF;
    
    -- Truncate if too long (leave room for suffix)
    base_username := LEFT(base_username, 20);
    
    -- Try base username first
    final_username := base_username;
    
    -- Handle collision with random suffix
    WHILE EXISTS (SELECT 1 FROM public.users WHERE username = final_username) LOOP
        counter := counter + 1;
        IF counter > 100 THEN
            -- Fallback to fully random
            final_username := 'user_' || substr(md5(random()::text), 1, 8);
            EXIT;
        END IF;
        final_username := base_username || '_' || substr(md5(random()::text), 1, 4);
    END LOOP;
    
    RETURN final_username;
END;
$$ LANGUAGE plpgsql;

-- ===================
-- USER PROFILE SYNC
-- ===================

-- Auto-create public.users record when auth.users is created
-- Uses UPSERT to handle race conditions
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, display_name, avatar_url)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', 'User'),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture', NULL)
    )
    ON CONFLICT (id) DO UPDATE SET
        display_name = COALESCE(EXCLUDED.display_name, public.users.display_name),
        avatar_url = COALESCE(EXCLUDED.avatar_url, public.users.avatar_url),
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===================
-- COUNTER UPDATES
-- ===================

-- Update like_count on works
CREATE OR REPLACE FUNCTION update_work_like_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.works SET like_count = like_count + 1 WHERE id = NEW.work_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.works SET like_count = like_count - 1 WHERE id = OLD.work_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update collect_count on works
CREATE OR REPLACE FUNCTION update_work_collect_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.works SET collect_count = collect_count + 1 WHERE id = NEW.work_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.works SET collect_count = collect_count - 1 WHERE id = OLD.work_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update comment_count on works
CREATE OR REPLACE FUNCTION update_work_comment_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.works SET comment_count = comment_count + 1 WHERE id = NEW.work_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.works SET comment_count = comment_count - 1 WHERE id = OLD.work_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===================
-- ACTIVITY NOTIFICATIONS
-- ===================

-- Create activity on like (skip if self-like)
CREATE OR REPLACE FUNCTION create_like_activity()
RETURNS TRIGGER AS $$
DECLARE
    work_owner_id UUID;
BEGIN
    SELECT user_id INTO work_owner_id FROM public.works WHERE id = NEW.work_id;
    
    IF work_owner_id IS NOT NULL AND work_owner_id != NEW.user_id THEN
        INSERT INTO public.activities (user_id, actor_id, type, work_id)
        VALUES (work_owner_id, NEW.user_id, 'like', NEW.work_id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create activity on collect (skip if self-collect)
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

-- Create activity on comment (skip if self-comment)
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

