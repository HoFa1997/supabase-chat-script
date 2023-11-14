-- MESSAGES
-- This table stores all messages exchanged in the application.
-- It includes timestamps for insertion, updates, and flags for deleted and edited messages.
-- Each message is linked to a user and a channel and can have various types like text, image, video, or audio.
CREATE TABLE public.messages (
  id                     UUID DEFAULT uuid_generate_v4() NOT NULL PRIMARY KEY, -- Unique identifier for each message.
  inserted_at            TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL, -- Timestamp when the message was created.
  updated_at             TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL, -- Timestamp for the last update of the message.
  deleted_at             TIMESTAMP WITH TIME ZONE, -- Timestamp when the message was deleted, if applicable.
  edited_at              TIMESTAMP WITH TIME ZONE, -- Timestamp when the message was edited, if applicable.
  content                TEXT NOT NULL, -- Main content of the message.
  media_urls             JSONB, -- JSONB field to store an array of media URLs.
  user_id                UUID REFERENCES public.users NOT NULL, -- Reference to the user who sent the message.
  channel_id             UUID REFERENCES public.channels ON DELETE SET NULL NOT NULL, -- Reference to the channel where the message was posted.
  reactions              JSONB, -- Stores reactions to the message in JSONB format.
  type                   message_type, -- Type of the message using the 'message_type' enum.
  metadata               JSONB, -- JSONB field for additional metadata about the message.
  reply_to_message_id    UUID REFERENCES public.messages(id), -- ID of the message being replied to, if any.
  replied_message_preview TEXT, -- Preview of the replied message.
  original_message_id    UUID REFERENCES public.messages(id) -- ID of the original message if this is a forwarded message.
);
comment on table public.messages is 'Individual messages sent by each user.';


-- PINNED MESSAGES
-- This table keeps track of messages that are pinned in channels.
CREATE TABLE public.pinned_messages (
  id            UUID DEFAULT uuid_generate_v4() NOT NULL PRIMARY KEY, -- Unique identifier for each pinned message entry.
  channel_id    UUID REFERENCES public.channels(id) ON DELETE CASCADE NOT NULL, -- Channel in which the message is pinned.
  message_id    UUID REFERENCES public.messages(id) ON DELETE CASCADE NOT NULL, -- The message that is pinned.
  pinned_at     TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL, -- Timestamp when the message was pinned.
  pinned_by     UUID REFERENCES public.users(id) NOT NULL, -- User who pinned the message.
  UNIQUE (channel_id, message_id)
);
COMMENT ON TABLE public.pinned_messages IS 'Tracks messages pinned in each channel.';
