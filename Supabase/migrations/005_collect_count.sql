-- ============================================
-- Add collect_count to works table
-- Version: 005
-- ============================================

-- Add collect_count column
ALTER TABLE public.works 
ADD COLUMN IF NOT EXISTS collect_count INTEGER DEFAULT 0;

-- Initialize collect_count from existing collections
UPDATE public.works w
SET collect_count = (
    SELECT COUNT(*) 
    FROM public.collections c 
    WHERE c.work_id = w.id
);

-- Create function to update collect_count
CREATE OR REPLACE FUNCTION update_work_collect_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.works 
        SET collect_count = collect_count + 1 
        WHERE id = NEW.work_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.works 
        SET collect_count = collect_count - 1 
        WHERE id = OLD.work_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for collections
DROP TRIGGER IF EXISTS trigger_update_collect_count ON public.collections;
CREATE TRIGGER trigger_update_collect_count
AFTER INSERT OR DELETE ON public.collections
FOR EACH ROW
EXECUTE FUNCTION update_work_collect_count();

