-- GolpoGhor RLS policies
-- Run in Supabase Dashboard → SQL Editor
-- Review table/column names if your schema differs slightly.

-- ========== HELPER ==========
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.app_admins a
    WHERE lower(a.email) = lower(auth.jwt() ->> 'email')
  )
  OR EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND coalesce(p.is_admin, false) = true
  );
$$;

-- ========== PROFILES ==========
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS profiles_select ON public.profiles;
CREATE POLICY profiles_select ON public.profiles
  FOR SELECT USING (true);

DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
CREATE POLICY profiles_update_own ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS profiles_admin_all ON public.profiles;
CREATE POLICY profiles_admin_all ON public.profiles
  FOR ALL USING (public.is_admin());

-- ========== STORIES ==========
ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS stories_public_read ON public.stories;
CREATE POLICY stories_public_read ON public.stories
  FOR SELECT USING (
    (is_published = true AND is_draft = false) OR author_id = auth.uid() OR public.is_admin()
  );

DROP POLICY IF EXISTS stories_insert_own ON public.stories;
CREATE POLICY stories_insert_own ON public.stories
  FOR INSERT WITH CHECK (auth.uid() = author_id);

DROP POLICY IF EXISTS stories_update_own ON public.stories;
CREATE POLICY stories_update_own ON public.stories
  FOR UPDATE USING (auth.uid() = author_id OR public.is_admin());

DROP POLICY IF EXISTS stories_delete_own ON public.stories;
CREATE POLICY stories_delete_own ON public.stories
  FOR DELETE USING (auth.uid() = author_id OR public.is_admin());

-- ========== NOVELS ==========
ALTER TABLE public.novels ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS novels_public_read ON public.novels;
CREATE POLICY novels_public_read ON public.novels
  FOR SELECT USING (
    (is_published = true AND coalesce(is_draft, false) = false) OR author_id = auth.uid() OR public.is_admin()
  );

DROP POLICY IF EXISTS novels_insert_own ON public.novels;
CREATE POLICY novels_insert_own ON public.novels
  FOR INSERT WITH CHECK (auth.uid() = author_id);

DROP POLICY IF EXISTS novels_update_own ON public.novels;
CREATE POLICY novels_update_own ON public.novels
  FOR UPDATE USING (auth.uid() = author_id OR public.is_admin());

DROP POLICY IF EXISTS novels_delete_own ON public.novels;
CREATE POLICY novels_delete_own ON public.novels
  FOR DELETE USING (auth.uid() = author_id OR public.is_admin());

-- ========== EPISODES ==========
ALTER TABLE public.episodes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS episodes_public_read ON public.episodes;
CREATE POLICY episodes_public_read ON public.episodes
  FOR SELECT USING (
    coalesce(is_published, true) = true OR author_id = auth.uid() OR public.is_admin()
  );

DROP POLICY IF EXISTS episodes_insert_own ON public.episodes;
CREATE POLICY episodes_insert_own ON public.episodes
  FOR INSERT WITH CHECK (auth.uid() = author_id);

DROP POLICY IF EXISTS episodes_update_own ON public.episodes;
CREATE POLICY episodes_update_own ON public.episodes
  FOR UPDATE USING (auth.uid() = author_id OR public.is_admin());

DROP POLICY IF EXISTS episodes_delete_own ON public.episodes;
CREATE POLICY episodes_delete_own ON public.episodes
  FOR DELETE USING (auth.uid() = author_id OR public.is_admin());

-- ========== COMMENTS ==========
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS comments_read ON public.comments;
CREATE POLICY comments_read ON public.comments FOR SELECT USING (true);

DROP POLICY IF EXISTS comments_insert ON public.comments;
CREATE POLICY comments_insert ON public.comments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS comments_delete_own ON public.comments;
CREATE POLICY comments_delete_own ON public.comments
  FOR DELETE USING (auth.uid() = user_id OR public.is_admin());

-- ========== REACTIONS / BOOKMARKS / FOLLOWS ==========
ALTER TABLE public.reactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS reactions_all_own ON public.reactions;
CREATE POLICY reactions_all_own ON public.reactions
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS bookmarks_all_own ON public.bookmarks;
CREATE POLICY bookmarks_all_own ON public.bookmarks
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS follows_read ON public.follows;
CREATE POLICY follows_read ON public.follows FOR SELECT USING (true);
DROP POLICY IF EXISTS follows_write ON public.follows;
CREATE POLICY follows_write ON public.follows
  FOR ALL USING (auth.uid() = follower_id) WITH CHECK (auth.uid() = follower_id);

-- ========== NOTIFICATIONS ==========
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS notifications_own ON public.notifications;
CREATE POLICY notifications_own ON public.notifications
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ========== REPORTS ==========
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS reports_insert ON public.reports;
CREATE POLICY reports_insert ON public.reports
  FOR INSERT WITH CHECK (auth.uid() = reporter_id);
DROP POLICY IF EXISTS reports_admin_read ON public.reports;
CREATE POLICY reports_admin_read ON public.reports
  FOR SELECT USING (auth.uid() = reporter_id OR public.is_admin());
DROP POLICY IF EXISTS reports_admin_update ON public.reports;
CREATE POLICY reports_admin_update ON public.reports
  FOR UPDATE USING (public.is_admin());

-- ========== VIDEO ==========
ALTER TABLE public.video_posts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS videos_read ON public.video_posts;
CREATE POLICY videos_read ON public.video_posts
  FOR SELECT USING (coalesce(is_published, true) = true OR author_id = auth.uid() OR public.is_admin());
DROP POLICY IF EXISTS videos_write ON public.video_posts;
CREATE POLICY videos_write ON public.video_posts
  FOR ALL USING (auth.uid() = author_id OR public.is_admin())
  WITH CHECK (auth.uid() = author_id OR public.is_admin());

-- Optional: enable realtime for notifications
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
