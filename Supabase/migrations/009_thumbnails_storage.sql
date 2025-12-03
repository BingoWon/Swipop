-- ============================================
-- Thumbnails Storage Bucket & RLS Policies
-- Version: 009
-- ============================================

-- 1. Create thumbnails bucket (public for reading)
INSERT INTO storage.buckets (id, name, public)
VALUES ('thumbnails', 'thumbnails', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. Drop existing policies if any (for idempotent migration)
DROP POLICY IF EXISTS "Users can upload their own thumbnails" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own thumbnails" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own thumbnails" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view thumbnails" ON storage.objects;
-- Also drop old "covers" policies if they exist
DROP POLICY IF EXISTS "Users can upload their own covers" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own covers" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own covers" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view covers" ON storage.objects;

-- 3. Allow authenticated users to upload to their own directory
-- Path format: {user_id}/{work_id}.jpg
-- Using LOWER() to handle UUID case differences
CREATE POLICY "Users can upload their own thumbnails"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'thumbnails' 
    AND LOWER((storage.foldername(name))[1]) = LOWER(auth.uid()::text)
);

-- 4. Allow authenticated users to update their own thumbnails
CREATE POLICY "Users can update their own thumbnails"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'thumbnails' 
    AND LOWER((storage.foldername(name))[1]) = LOWER(auth.uid()::text)
);

-- 5. Allow authenticated users to delete their own thumbnails
CREATE POLICY "Users can delete their own thumbnails"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'thumbnails' 
    AND LOWER((storage.foldername(name))[1]) = LOWER(auth.uid()::text)
);

-- 6. Allow anyone to view thumbnails (public bucket)
CREATE POLICY "Anyone can view thumbnails"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'thumbnails');
