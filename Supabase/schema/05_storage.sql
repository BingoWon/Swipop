-- ============================================
-- Storage Buckets and Policies
-- Current state as of 2024
-- ============================================

-- ===================
-- BUCKETS
-- ===================

-- Avatars bucket (public read)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Thumbnails bucket (public read)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('thumbnails', 'thumbnails', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Project assets bucket (public read)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('project-assets', 'project-assets', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- ===================
-- AVATARS POLICIES
-- ===================
-- Path format: {user_id}/avatar.{ext}

DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
CREATE POLICY "Avatar images are publicly accessible"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
CREATE POLICY "Users can upload their own avatar"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'avatars' 
        AND LOWER((storage.foldername(name))[1]) = LOWER(auth.uid()::text)
    );

DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
CREATE POLICY "Users can update their own avatar"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'avatars' 
        AND LOWER((storage.foldername(name))[1]) = LOWER(auth.uid()::text)
    );

DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;
CREATE POLICY "Users can delete their own avatar"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'avatars' 
        AND LOWER((storage.foldername(name))[1]) = LOWER(auth.uid()::text)
    );

-- ===================
-- THUMBNAILS POLICIES
-- ===================
-- Path format: {user_id}/{project_id}.jpg

DROP POLICY IF EXISTS "Anyone can view thumbnails" ON storage.objects;
CREATE POLICY "Anyone can view thumbnails"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'thumbnails');

DROP POLICY IF EXISTS "Users can upload their own thumbnails" ON storage.objects;
CREATE POLICY "Users can upload their own thumbnails"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'thumbnails' 
        AND LOWER((storage.foldername(name))[1]) = LOWER(auth.uid()::text)
    );

DROP POLICY IF EXISTS "Users can update their own thumbnails" ON storage.objects;
CREATE POLICY "Users can update their own thumbnails"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'thumbnails' 
        AND LOWER((storage.foldername(name))[1]) = LOWER(auth.uid()::text)
    );

DROP POLICY IF EXISTS "Users can delete their own thumbnails" ON storage.objects;
CREATE POLICY "Users can delete their own thumbnails"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'thumbnails' 
        AND LOWER((storage.foldername(name))[1]) = LOWER(auth.uid()::text)
    );

-- ===================
-- PROJECT ASSETS POLICIES
-- ===================
-- Path format: {user_id}/{project_id}/{asset_name}

DROP POLICY IF EXISTS "Project assets are publicly accessible" ON storage.objects;
CREATE POLICY "Project assets are publicly accessible"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'project-assets');

DROP POLICY IF EXISTS "Users can upload project assets" ON storage.objects;
CREATE POLICY "Users can upload project assets"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'project-assets' 
        AND LOWER((storage.foldername(name))[1]) = LOWER(auth.uid()::text)
    );

DROP POLICY IF EXISTS "Users can update their own project assets" ON storage.objects;
CREATE POLICY "Users can update their own project assets"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'project-assets' 
        AND LOWER((storage.foldername(name))[1]) = LOWER(auth.uid()::text)
    );

DROP POLICY IF EXISTS "Users can delete their own project assets" ON storage.objects;
CREATE POLICY "Users can delete their own project assets"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'project-assets' 
        AND LOWER((storage.foldername(name))[1]) = LOWER(auth.uid()::text)
    );

