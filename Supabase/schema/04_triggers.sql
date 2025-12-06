-- ============================================
-- Database Triggers
-- Current state as of 2024
-- ============================================

-- ===================
-- UPDATED_AT TRIGGERS
-- ===================
-- Auto-update updated_at column on record modification

DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_projects_updated_at ON public.projects;
CREATE TRIGGER update_projects_updated_at
    BEFORE UPDATE ON public.projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_comments_updated_at ON public.comments;
CREATE TRIGGER update_comments_updated_at
    BEFORE UPDATE ON public.comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ===================
-- USER SYNC TRIGGER
-- ===================
-- Create public.users record when auth.users is created

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ===================
-- COUNTER TRIGGERS
-- ===================
-- Maintain denormalized counters on projects table

DROP TRIGGER IF EXISTS on_like_change ON public.likes;
CREATE TRIGGER on_like_change
    AFTER INSERT OR DELETE ON public.likes
    FOR EACH ROW EXECUTE FUNCTION update_project_like_count();

DROP TRIGGER IF EXISTS on_collect_change ON public.collections;
CREATE TRIGGER on_collect_change
    AFTER INSERT OR DELETE ON public.collections
    FOR EACH ROW EXECUTE FUNCTION update_project_collect_count();

DROP TRIGGER IF EXISTS on_comment_change ON public.comments;
CREATE TRIGGER on_comment_change
    AFTER INSERT OR DELETE ON public.comments
    FOR EACH ROW EXECUTE FUNCTION update_project_comment_count();

-- ===================
-- ACTIVITY TRIGGERS
-- ===================
-- Create notification records on user actions

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

