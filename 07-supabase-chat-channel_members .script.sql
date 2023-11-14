

-- This table tracks the membership of users in channels.
-- It records the last message read by each user in a channel to maintain read status.
CREATE TABLE public.channel_members (
  channel_id UUID REFERENCES public.channels(id) ON DELETE CASCADE, -- Channel ID, deletes member records if channel is deleted.
  member_id UUID REFERENCES public.users(id) ON DELETE CASCADE, -- Member's User ID, deletes member records if user is deleted.
  last_read_message_id UUID REFERENCES public.messages(id), -- Last message read by the user in the channel.
  last_read_update TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()), -- Timestamp of the last read update.
  UNIQUE (channel_id, member_id) -- Ensures unique membership records per channel.
);
COMMENT ON TABLE public.channel_members IS 'Tracks the membership of users in channels.';