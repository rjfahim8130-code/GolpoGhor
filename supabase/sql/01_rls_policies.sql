-- GolpoGhor RLS policies
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.app_admins a WHERE lower(a.email) = lower(auth.jwt() ->> 'email'))
  OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND coalesce(p.is_admin, false) = true);
$$;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY profiles_select ON public.profiles FOR SELECT USING (true);
CREATE POLICY profiles_update_own ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY profiles_admin_all ON public.profiles FOR ALL USING (public.is_admin());

ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;
CREATE POLICY stories_public_read ON public.stories FOR SELECT USING ((is_published = true AND is_draft = false) OR author_id = auth.uid() OR public.is_admin());
CREATE POLICY stories_insert_own ON public.stories FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY stories_update_own ON public.stories FOR UPDATE USING (auth.uid() = author_id OR public.is_admin());
CREATE POLICY stories_delete_own ON public.stories FOR DELETE USING (auth.uid() = author_id OR public.is_admin());

ALTER TABLE public.novels ENABLE ROW LEVEL SECURITY;
CREATE POLICY novels_public_read ON public.novels FOR SELECT USING ((is_published = true AND coalesce(is_draft, false) = false) OR author_id = auth.uid() OR public.is_admin());
CREATE POLICY novels_insert_own ON public.novels FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY novels_update_own ON public.novels FOR UPDATE USING (auth.uid() = author_id OR public.is_admin());
CREATE POLICY novels_delete_own ON public.novels FOR DELETE USING (auth.uid() = author_id OR public.is_admin());

ALTER TABLE public.episodes ENABLE ROW LEVEL SECURITY;
CREATE POLICY episodes_public_read ON public.episodes FOR SELECT USING (coalesce(is_published, true) = true OR author_id = auth.uid() OR public.is_admin());
CREATE POLICY episodes_insert_own ON public.episodes FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY episodes_update_own ON public.episodes FOR UPDATE USING (auth.uid() = author_id OR public.is_admin());
CREATE POLICY episodes_delete_own ON public.episodes FOR DELETE USING (auth.uid() = author_id OR public.is_admin());

ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY comments_read ON public.comments FOR SELECT USING (coalesce(is_deleted, false) = false OR user_id = auth.uid() OR public.is_admin());
CREATE POLICY comments_insert ON public.comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY comments_delete_own ON public.comments FOR DELETE USING (auth.uid() = user_id OR public.is_admin());

ALTER TABLE public.reactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY reactions_select_all ON public.reactions FOR SELECT USING (true);
CREATE POLICY reactions_insert_own ON public.reactions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY reactions_delete_own ON public.reactions FOR DELETE USING (auth.uid() = user_id);

ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;
CREATE POLICY bookmarks_select_all ON public.bookmarks FOR SELECT USING (true);
CREATE POLICY bookmarks_insert_own ON public.bookmarks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY bookmarks_delete_own ON public.bookmarks FOR DELETE USING (auth.uid() = user_id);

ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
CREATE POLICY follows_read ON public.follows FOR SELECT USING (true);
CREATE POLICY follows_write ON public.follows FOR ALL USING (auth.uid() = follower_id) WITH CHECK (auth.uid() = follower_id);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY notifications_own ON public.notifications FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY reports_insert ON public.reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);
CREATE POLICY reports_admin_read ON public.reports FOR SELECT USING (auth.uid() = reporter_id OR public.is_admin());
CREATE POLICY reports_admin_update ON public.reports FOR UPDATE USING (public.is_admin());

ALTER TABLE public.video_posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY videos_read ON public.video_posts FOR SELECT USING (coalesce(is_published, true) = true OR author_id = auth.uid() OR public.is_admin());
CREATE POLICY videos_write ON public.video_posts FOR ALL USING (auth.uid() = author_id OR public.is_admin()) WITH CHECK (auth.uid() = author_id OR public.is_admin());
