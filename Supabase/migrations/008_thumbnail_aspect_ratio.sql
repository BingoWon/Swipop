-- ============================================
-- Add thumbnail_aspect_ratio to works table
-- Version: 008
-- ============================================

-- Add thumbnail_aspect_ratio column (width / height)
-- Range: 0.75 (3:4 portrait) to 1.33 (4:3 landscape)
-- Default: 0.75 (most common for mobile screenshots)
ALTER TABLE public.works 
ADD COLUMN IF NOT EXISTS thumbnail_aspect_ratio REAL DEFAULT 0.75;

-- Add comment for documentation
COMMENT ON COLUMN public.works.thumbnail_aspect_ratio IS 'Thumbnail image aspect ratio (width/height). Range: 0.75 to 1.33';

