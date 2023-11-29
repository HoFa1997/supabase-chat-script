-- Table: public.messages
-- Description: Stores all messages exchanged in the application. This includes various types of messages like text, image, video, or audio. 
-- The table also tracks message status (edited, deleted) and associations (user, channel, replies, and forwardings).
CREATE TABLE public.messages (
    id                     UUID DEFAULT uuid_generate_v4() NOT NULL PRIMARY KEY,
    created_at             TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL, -- Creation timestamp of the message.
    updated_at             TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL, -- Last update timestamp of the message.
    deleted_at             TIMESTAMP WITH TIME ZONE, -- Timestamp for when the message was marked as deleted.
    edited_at              TIMESTAMP WITH TIME ZONE, -- Timestamp for when the message was edited.
    content                TEXT, -- The actual text content of the message.
    html                   TEXT, -- The actual HTML content of the message.
    medias                 JSONB, -- Stores URLs to media (images, videos, etc.) associated with the message.
    user_id                UUID NOT NULL REFERENCES public.users, -- The ID of the user who sent the message.
    channel_id             UUID NOT NULL REFERENCES public.channels ON DELETE SET NULL, -- The ID of the channel where the message was sent.
    reactions              JSONB, -- JSONB field storing user reactions to the message.
    type                   message_type, -- Enumerated type of the message (text, image, video, etc.).
    metadata               JSONB, -- Additional metadata about the message in JSONB format.
    reply_to_message_id    UUID REFERENCES public.messages(id) ON DELETE SET NULL, -- The ID of the message this message is replying to, if any.
    replied_message_preview TEXT, -- Preview text of the message being replied to.
    original_message_id    UUID REFERENCES public.messages(id) ON DELETE SET NULL -- ID of the original message if this is a forwarded message.
);

COMMENT ON TABLE public.messages IS 'Contains individual messages sent by users, including their content, type, and associated metadata.';


-- NOTE: write more about the purpose of each column.


-- public.messages.reaction and .medias Jsonb can be look like this:


-- const metadata = {
--  replied:['user_id1', 'userid2'],
--  forwarding_chain: [
--    {user_id: 'user_id1', username: 'john', 'full_nam': 'John Doe'},
--    {user_id: 'user_id2', username: 'jane', 'full_nam': 'Jane Doe'},
--  ],
--}

-- const medias = [
--   {
--     url: 'https://www.youtube.com/watch?v=9bZkp7q19f0',
--     type: 'video',
--     description: "Gangnam Style"
--   },
--   {
--     url: 'https://www.youtube.com/watch?v=9bZkp7q19f0',
--     type: 'video',
--     description: "Gangnam Style"
--   }
-- ]

-- const reactions = {
--    '😄': ['user_id1', 'user_id2', 'user_id3'],
--    '👍': ['user_id1', 'user_id2', 'user_id3'],
-- }
-- OR
-- const reactions = {
--    '😄': [
--     {user_id: 'user_id1', created_at: '2021-01-01T00:00:00.000Z'},
--   ],
--    '👍': ['user_id1', 'user_id2', user_id3],
-- }

