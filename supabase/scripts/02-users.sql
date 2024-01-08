-- Table: public.users
-- Description: This table holds essential information about each user within the application. 
-- It includes user identification, personal and contact details, and system-related information.
CREATE TABLE public.users (
    id              UUID NOT NULL PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
    username        TEXT NOT NULL UNIQUE,      -- The username chosen by the user, ensured to be unique across the system.
    full_name       TEXT,               -- Full name of the user.
    display_name    TEXT,              -- Display name of the user.
    status      user_status DEFAULT 'OFFLINE'::public.user_status,  -- Current online/offline status of the user. Defaults to 'OFFLINE'.
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL, -- Timestamp of the last update, automatically set to the current UTC time.
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL, -- Timestamp of the user's creation, automatically set to the current UTC time.
    avatar_url  TEXT,               -- URL of the user's avatar image.
    website     TEXT,               -- User's personal or professional website.
    email       TEXT UNIQUE,        -- User's email address.
    description TEXT,               -- Brief description or bio of the user.
    CONSTRAINT username_length CHECK (char_length(username) >= 3), -- Ensures that usernames are at least 3 characters long.
    last_seen_at TIMESTAMP WITH TIME ZONE  -- Timestamp of the last time the user was seen online.
);

COMMENT ON TABLE public.users IS 'Profile data for each user, including identification, personal info, and system timestamps.';
COMMENT ON COLUMN public.users.id IS 'References the internal Supabase Auth user ID, ensuring linkage with authentication data.';
COMMENT ON COLUMN public.users.username IS 'Unique username for each user, serving as a key identifier within the system.';
COMMENT ON COLUMN public.users.status IS 'Represents the current online/offline status of the user, based on the user_status enum.';



-- This cron job is scheduled to run every 5 minutes. Its purpose is to update the status of users in the `public.users` table. 
-- It sets the status to 'OFFLINE' for users who have not been active (as indicated by their `last_seen_at` timestamp) for more than 5 minutes.
-- This ensures that the user status remains up-to-date, reflecting whether they are currently active or inactive in the application.
SELECT cron.schedule(
    'update-user-status',
    '*/5 * * * *',
    $$ 
    UPDATE public.users
    SET status = 'OFFLINE'
    WHERE last_seen_at < NOW() - INTERVAL '5 minutes' AND status = 'ONLINE';
    $$ 
);
