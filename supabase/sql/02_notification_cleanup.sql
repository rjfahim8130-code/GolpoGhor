-- Delete notifications older than 2 days (run via pg_cron or manual schedule)
CREATE OR REPLACE FUNCTION public.cleanup_old_notifications()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  DELETE FROM public.notifications
  WHERE created_at < now() - interval '2 days';
$$;

-- If pg_cron is available:
-- SELECT cron.schedule('cleanup_notifications', '0 3 * * *', $$SELECT public.cleanup_old_notifications();$$);
