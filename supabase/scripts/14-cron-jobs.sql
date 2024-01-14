-- This cron job is scheduled to run every 5 minutes. Its purpose is to update the status of users in the `public.users` table. 
-- It sets the status to 'OFFLINE' for users who have not been active (as indicated by their `last_seen_at` timestamp) for more than 5 minutes.
-- This ensures that the user status remains up-to-date, reflecting whether they are currently active or inactive in the application.
-- NOTE: Active the pg_cron Extension in Supabase.
SELECT cron.schedule(
    'update-user-status',
    '*/5 * * * *',
    $$ 
    UPDATE public.users
    SET status = 'OFFLINE'
    WHERE last_seen_at < NOW() - INTERVAL '5 minutes' AND status = 'ONLINE';
    $$ 
);
