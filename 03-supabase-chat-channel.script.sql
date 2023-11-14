-- CHANNELS
-- This table represents the channels in the application, similar to chat rooms or discussion groups.
create table public.channels (
  id                  uuid DEFAULT uuid_generate_v4() not null primary key, -- Unique identifier for each channel.
  inserted_at         timestamp with time zone default timezone('utc'::text, now()) not null, -- Timestamp of channel creation.
  slug                text not null unique, -- URL-friendly unique identifier for the channel.
  created_by          uuid references public.users not null, -- User ID of the channel creator.
  is_private          boolean default false, -- True if the channel is private, false if public.
  is_read_only        boolean default false, -- True if the channel is read-only.
  description         TEXT CHECK (length(description) <= 1000), -- A brief description of the channel's purpose.
  member_limit        INT, -- Maximum number of members allowed in the channel.
  is_archived         boolean default false, -- True if the channel is archived.
  last_activity_at    timestamp with time zone default timezone('utc'::text, now()) not null, -- Timestamp of the last activity in the channel.
  last_message_preview TEXT -- Preview of the last message sent in the channel.
);


ALTER TABLE public.channels ADD CONSTRAINT check_slug_format CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$');
comment on table public.channels is 'Channels for group discussions and messaging.';
