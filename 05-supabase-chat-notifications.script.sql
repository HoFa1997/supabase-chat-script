-- This table handles notifications for users.
-- Notifications can be for messages, channel invites, or other types.
CREATE TABLE public.notifications (
  id              UUID DEFAULT uuid_generate_v4() NOT NULL PRIMARY KEY, -- Unique identifier for each notification.
  user_id         UUID REFERENCES public.users NOT NULL, -- User who receives the notification.
  type            notification_type NOT NULL,
  message_id      UUID REFERENCES public.messages ON DELETE CASCADE,  -- Reference message 
  mention_id      UUID REFERENCES public.channels ON DELETE CASCADE,  -- Reference mention 
  message_preview TEXT, -- Preview of the message, if applicable.
  created_at      TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL, -- Creation timestamp of the notification.
  read_at         TIMESTAMP WITH TIME ZONE -- Timestamp when the notification was read.
);
COMMENT ON TABLE public.notifications IS 'Notifications sent to users.';