-- ============================================
-- Add chat_messages and tags to works table
-- Version: 007
-- ============================================

-- Add chat_messages column for storing conversation history
ALTER TABLE public.works 
ADD COLUMN IF NOT EXISTS chat_messages JSONB DEFAULT '[]'::jsonb;

-- Add tags column for work discovery
ALTER TABLE public.works 
ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';

-- Make title optional (allow empty string for drafts)
ALTER TABLE public.works 
ALTER COLUMN title SET DEFAULT '';

-- Allow null title for existing constraint
ALTER TABLE public.works 
ALTER COLUMN title DROP NOT NULL;

-- Add index for tags search
CREATE INDEX IF NOT EXISTS idx_works_tags ON public.works USING GIN(tags);

-- Update RLS policy to allow users to see their own drafts
DROP POLICY IF EXISTS "Users can view own works" ON public.works;
CREATE POLICY "Users can view own works" ON public.works
    FOR SELECT USING (
        user_id = auth.uid() OR is_published = true
    );

-- Policy for inserting own works
DROP POLICY IF EXISTS "Users can insert own works" ON public.works;
CREATE POLICY "Users can insert own works" ON public.works
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Policy for updating own works
DROP POLICY IF EXISTS "Users can update own works" ON public.works;
CREATE POLICY "Users can update own works" ON public.works
    FOR UPDATE USING (user_id = auth.uid());

-- Policy for deleting own works
DROP POLICY IF EXISTS "Users can delete own works" ON public.works;
CREATE POLICY "Users can delete own works" ON public.works
    FOR DELETE USING (user_id = auth.uid());

