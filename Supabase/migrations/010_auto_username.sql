-- ============================================
-- Auto-generate username from display_name
-- Version: 010
-- ============================================

-- Function to generate username from display_name
-- Converts to lowercase, replaces spaces with underscores, removes special chars
-- Appends random suffix if collision occurs
CREATE OR REPLACE FUNCTION generate_username(display_name TEXT)
RETURNS TEXT AS $$
DECLARE
    base_username TEXT;
    final_username TEXT;
    counter INTEGER := 0;
BEGIN
    -- Generate base username: lowercase, replace spaces, keep only alphanumeric and underscore
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
    
    -- Check for collision and append random suffix if needed
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

-- Updated function to create user profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    user_display_name TEXT;
    user_username TEXT;
BEGIN
    -- Extract display name from OAuth metadata
    user_display_name := COALESCE(
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'name',
        'User'
    );
    
    -- Generate username from display name
    user_username := generate_username(user_display_name);
    
    INSERT INTO public.users (id, username, display_name, avatar_url)
    VALUES (
        NEW.id,
        user_username,
        user_display_name,
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture', NULL)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Backfill existing users without username
UPDATE public.users
SET username = generate_username(display_name)
WHERE username IS NULL;

