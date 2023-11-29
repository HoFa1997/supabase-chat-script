-- DUMMY DATA

/*
    -----------------------------------------
    1. Create Users
       Expectation: 6 users should be created.
    -----------------------------------------
*/
insert into auth.users (id, email)
values
    ('8d0fd2b3-9ca7-4d9e-a95f-9e13dded323e', 'supabot'),
    ('5f55998b-7958-4ae3-bcb7-539c65c00884', 'jack'),
    ('1059dbd0-3478-46f9-b8a9-dcd23ed0a23a', 'emma'),
    ('dc7d6520-8408-4a8b-b628-78d5f82b8b62', 'jhon'),
    ('c2e3e9e7-d0e8-4960-9b05-d263deb2722f', 'lisa'),
    ('35477c6b-f9a0-4bad-af0b-545c99b33fae', 'philip');

/*
    -----------------------------------------
    2. Create Channels
       Expectation: 7 channels should be created with descriptions and types.
                    The created_by field should be set to the user who created the channel,
                    and that user should be added as an Admin in the channel_members table.
    -----------------------------------------
*/
insert into public.channels (id, slug, name, created_by, description, type)
values
    ('4b9f0f7e-6cd5-49b6-a8c3-141ef5905959', 'public', 'Public', '8d0fd2b3-9ca7-4d9e-a95f-9e13dded323e', 'General public discussions', 'PUBLIC'), 
    ('27c6745d-cebd-4afd-92b0-3b9b9312381b', 'random', 'Random', '8d0fd2b3-9ca7-4d9e-a95f-9e13dded323e', 'Random thoughts and ideas', 'PUBLIC'), 
    ('7ea75977-9bc0-4008-b5b8-13c56d16a588', 'game-boy', 'GameBoy', '35477c6b-f9a0-4bad-af0b-545c99b33fae', 'Game boy, win game awards, etc.', 'BROADCAST'),
    ('4d582754-4d72-48f8-9e72-f6aa63dacada', 'netfilix', 'Netfilix', '35477c6b-f9a0-4bad-af0b-545c99b33fae', 'Let’s talk about Netflix series', 'PRIVATE'),
    ('70ceab8b-2cf6-4004-8561-219de9b11ec2', 'movie-night', 'Movie Night', '1059dbd0-3478-46f9-b8a9-dcd23ed0a23a', 'Movie suggestions and discussions', 'DIRECT'),
    ('dc6a0f60-5260-456b-a5c7-b799cece8807', 'openai', 'OpenAI', 'dc7d6520-8408-4a8b-b628-78d5f82b8b62', 'What’s happening with OpenAI?', 'BROADCAST'),
    ('1292efc2-0cdc-470c-9364-ba76f19ce75d', 'tech-talk', 'Tech Yalk', 'c2e3e9e7-d0e8-4960-9b05-d263deb2722f', 'Discussions about the latest in tech', 'GROUP');

-- Mapping of channels with types and the user who created them.
-- public       -> PUBLIC       -> supabot
-- random       -> PUBLIC       -> supabot
-- game-boy     -> BROADCAST    -> philip
-- netfilix     -> PRIVATE      -> philip
-- movie-night  -> DIRECT       -> emma
-- openai       -> BROADCAST    -> jhon
-- tech-talk    -> GROUP        -> lisa

/* 
    -----------------------------------------
    3. Join Users to Channels
       Expectation: Users should be joined to channels as members.
    -----------------------------------------
*/
insert into public.channel_members (channel_id, member_id)
values

    -- Owner and Admin -> philip
    ('7ea75977-9bc0-4008-b5b8-13c56d16a588', '5f55998b-7958-4ae3-bcb7-539c65c00884'), -- game-boy   ==join==>   jack
    ('7ea75977-9bc0-4008-b5b8-13c56d16a588', '1059dbd0-3478-46f9-b8a9-dcd23ed0a23a'), -- game-boy   ==join==>   emma
    
    -- Owner and Admin -> philip
    ('4d582754-4d72-48f8-9e72-f6aa63dacada', 'c2e3e9e7-d0e8-4960-9b05-d263deb2722f'), -- netfilix   ==join==>   lisa
    ('4d582754-4d72-48f8-9e72-f6aa63dacada', '1059dbd0-3478-46f9-b8a9-dcd23ed0a23a'), -- netfilix   ==join==>   emma

    -- Owner and Admin -> emma
    ('70ceab8b-2cf6-4004-8561-219de9b11ec2', 'c2e3e9e7-d0e8-4960-9b05-d263deb2722f'), -- movie-night   ==join==>   lisa

    -- Owner and Admin -> lisa
    ('1292efc2-0cdc-470c-9364-ba76f19ce75d', '5f55998b-7958-4ae3-bcb7-539c65c00884'), -- tech-talk  ==join==>   jack
    ('1292efc2-0cdc-470c-9364-ba76f19ce75d', '1059dbd0-3478-46f9-b8a9-dcd23ed0a23a'), -- tech-talk  ==join==>   emma
    ('1292efc2-0cdc-470c-9364-ba76f19ce75d', 'dc7d6520-8408-4a8b-b628-78d5f82b8b62'), -- tech-talk  ==join==>   jhon
    ('1292efc2-0cdc-470c-9364-ba76f19ce75d', '35477c6b-f9a0-4bad-af0b-545c99b33fae'), -- tech-talk  ==join==>   philip

    -- Owner and Admin -> john
    ('dc6a0f60-5260-456b-a5c7-b799cece8807', '35477c6b-f9a0-4bad-af0b-545c99b33fae'), -- openai     ==join==>   philip
    ('dc6a0f60-5260-456b-a5c7-b799cece8807', '5f55998b-7958-4ae3-bcb7-539c65c00884'); -- openai     ==join==>   jack

/* 
    -----------------------------------------
    4. Create Random Messages
       Expectations: 
           - Five messages should be created.
           - Channel's last message preview must be updated.
           - Messages longer than 70 characters should be truncated.
           - Update unread message counts and previews for each channel.
           - Ensure the total number of notifications equals the number of unread messages.
    -----------------------------------------
*/

insert into public.messages (id, content, channel_id, user_id)
values
    (
    '84fd39d1-4467-4181-b07d-b4e9573bc8f9', 
    'Hello World 👋',
    '4b9f0f7e-6cd5-49b6-a8c3-141ef5905959', '8d0fd2b3-9ca7-4d9e-a95f-9e13dded323e' -- public -- supabot
    ),
    (
    '0363b237-8a72-462c-91b5-f5ee40958cf5', 
    'Perfection is attained, not when there is nothing more to add, but when there is nothing left to take away.', 
    '27c6745d-cebd-4afd-92b0-3b9b9312381b',  '8d0fd2b3-9ca7-4d9e-a95f-9e13dded323e' -- random -- supabot
    ),
    (
    '5de80678-2e4b-4850-ae0e-4e71afaf61bb',
    'hey, whats up, what do we have for this weekend?', 
    '4d582754-4d72-48f8-9e72-f6aa63dacada', 'c2e3e9e7-d0e8-4960-9b05-d263deb2722f'  -- netfilix -- lisa
    ),
    (
    '46e33eff-3a56-4619-bb7c-07e3e96af041',
    'whats up?',
    '4d582754-4d72-48f8-9e72-f6aa63dacada', 'c2e3e9e7-d0e8-4960-9b05-d263deb2722f' -- netfilix -- lisa
    ),
    (
    '7e84eca7-cf38-4eee-8127-847e78727ea5',
    'We have new event, follow up in this link...',
    '7ea75977-9bc0-4008-b5b8-13c56d16a588',  '35477c6b-f9a0-4bad-af0b-545c99b33fae' -- game-boy -- philip
    );



--- test qeury expections
-- test 1. count of messages in channel
select count(*) from public.messages where channel_id = '4d582754-4d72-48f8-9e72-f6aa63dacada';
-- test 2. last message preview
select content from public.messages where channel_id = '4d582754-4d72-48f8-9e72-f6aa63dacada' order by created_at desc limit 1;
--- ... and so on

/*
    -----------------------------------------
    5. Pin Messages
       Expectation: A new pinned message for the game-boy channel should be created by Philip.
    -----------------------------------------
*/

-- step 1: create a message
insert into public.pinned_messages (channel_id, message_id, pinned_by)
values
    ('7ea75977-9bc0-4008-b5b8-13c56d16a588', '7e84eca7-cf38-4eee-8127-847e78727ea5', '35477c6b-f9a0-4bad-af0b-545c99b33fae');

/*
    -----------------------------------------
    6. Emoji Reactions to Messages
       Expectation: Two reactions should be added to the message.
    -----------------------------------------
*/
-- step 1: create a message
INSERT INTO public.messages (id, content, channel_id, user_id)
VALUES (
    'f8d2002b-01ff-4c4a-9375-92c24e942950',
    'Exciting news about upcoming features!', 
    '4d582754-4d72-48f8-9e72-f6aa63dacada', 
    '35477c6b-f9a0-4bad-af0b-545c99b33fae'
);

-- step 2: add a reaction to the message
UPDATE public.messages
SET reactions = jsonb_set(
    COALESCE(reactions, '{}'), 
    '{😄}', 
    COALESCE(reactions->'😄', '[]') || jsonb_build_array(jsonb_build_object('user_id', '5f55998b-7958-4ae3-bcb7-539c65c00884', 'created_at', current_timestamp)),
    true
)
WHERE id = 'f8d2002b-01ff-4c4a-9375-92c24e942950';

-- step 3: add another reaction to the message
UPDATE public.messages
SET reactions = jsonb_set(
    COALESCE(reactions, '{}'), 
    '{👍}', 
    COALESCE(reactions->'👍', '[]') || jsonb_build_array(jsonb_build_object('user_id', 'dc7d6520-8408-4a8b-b628-78d5f82b8b62', 'created_at', current_timestamp)),
    true
)
WHERE id = 'f8d2002b-01ff-4c4a-9375-92c24e942950';

/*
    -----------------------------------------
    7. Reply to Messages
       Expectation: 
            1. Two messages should be attached to the first message as replies.
            2. The metadata of the first message should be updated accordingly.
    -----------------------------------------
*/

-- step 1: create a message
INSERT INTO public.messages (id, content, channel_id, user_id )
VALUES 
(   
    '1a3485e7-48eb-4fd1-afe1-3bb5506e4fe1', -- ID
    'Whos excited for the new Netflix series?', -- Content
    '4d582754-4d72-48f8-9e72-f6aa63dacada', -- Channel: netfilix
    '1059dbd0-3478-46f9-b8a9-dcd23ed0a23a' -- User: emma
);

-- step 2: reply to the message
INSERT INTO public.messages (channel_id, user_id, content, reply_to_message_id)
VALUES 
(
    '4d582754-4d72-48f8-9e72-f6aa63dacada', -- Channel: netfilix
    'c2e3e9e7-d0e8-4960-9b05-d263deb2722f', -- User: lisa
    'I am! Cant wait to watch it.', -- Content
    '1a3485e7-48eb-4fd1-afe1-3bb5506e4fe1' -- original message id
),
(
    '4d582754-4d72-48f8-9e72-f6aa63dacada', -- Channel: netfilix
    '35477c6b-f9a0-4bad-af0b-545c99b33fae', -- User: philip
    'Do you know when its releasing?', -- Content
    '1a3485e7-48eb-4fd1-afe1-3bb5506e4fe1' -- original message id
);


/*
    -----------------------------------------
    8. Forward Messages
       Expectation: Define specific expectations here.
    -----------------------------------------
*/

-- step 1: create a message
INSERT INTO public.messages (id, content, channel_id, user_id )
values
(
    '0486ed3d-8e48-49ed-b8af-2387909f642f', -- ID
    'Exciting news about upcoming features!', -- Content
    '4d582754-4d72-48f8-9e72-f6aa63dacada', -- Channel: netfilix
    '35477c6b-f9a0-4bad-af0b-545c99b33fae' -- User: Philip
);

-- step 2: add reaction to the message
UPDATE public.messages
SET reactions = jsonb_set(
    COALESCE(reactions, '{}'), 
    '{👍}', 
    COALESCE(reactions->'👍', '[]') || jsonb_build_array(jsonb_build_object('user_id', 'dc7d6520-8408-4a8b-b628-78d5f82b8b62', 'created_at', current_timestamp)),
    true
)
WHERE id = '0486ed3d-8e48-49ed-b8af-2387909f642f';

-- step 3: add a custom metadata to the message
UPDATE public.messages
SET metadata = jsonb_set(
    COALESCE(metadata, '{}'), 
    '{is_important}', 
    'true',
    true
)
WHERE id = '0486ed3d-8e48-49ed-b8af-2387909f642f';

-- step 5: reply to the message
INSERT INTO public.messages (channel_id, user_id, content, reply_to_message_id)
VALUES(
    '4d582754-4d72-48f8-9e72-f6aa63dacada', -- Channel: netfilix
    '5f55998b-7958-4ae3-bcb7-539c65c00884', -- User: Jack
    'I am! Cant wait to watch it.', -- Content
    '0486ed3d-8e48-49ed-b8af-2387909f642f' -- original message id
);

-- step 6: forward the message
INSERT INTO public.messages (id, channel_id, user_id, original_message_id)
values
(   
    '8c6a047a-4e0f-46eb-8e7d-0f4357fabc86', -- ID
    'dc6a0f60-5260-456b-a5c7-b799cece8807', -- Channel: openai
    'dc7d6520-8408-4a8b-b628-78d5f82b8b62', -- User: Jhon
    '0486ed3d-8e48-49ed-b8af-2387909f642f' -- original message id
),
(
    'bb27aacc-e31a-4664-9606-103972702dd5', -- ID
    '1292efc2-0cdc-470c-9364-ba76f19ce75d', -- Channel: tech-talk
    'c2e3e9e7-d0e8-4960-9b05-d263deb2722f', -- User: Lisa
    '0486ed3d-8e48-49ed-b8af-2387909f642f' -- original message id
);

-- step 7: forward the forwarded message
INSERT INTO public.messages (id, channel_id, user_id, original_message_id)
values
(
    '4701aef9-cfcc-45e2-80ec-e0f3ffdc25dc', -- ID
    '70ceab8b-2cf6-4004-8561-219de9b11ec2', -- Channel: movie-night
    '1059dbd0-3478-46f9-b8a9-dcd23ed0a23a', -- User: Emma
    '8c6a047a-4e0f-46eb-8e7d-0f4357fabc86' -- original message id
);

-- step 8: add reaction to the forwarded message
UPDATE public.messages
SET reactions = jsonb_set(
    COALESCE(reactions, '{}'), 
    '{😼}', 
    COALESCE(reactions->'😼', '[]') || jsonb_build_array(jsonb_build_object('user_id', '5f55998b-7958-4ae3-bcb7-539c65c00884', 'created_at', current_timestamp)),
    true
)
WHERE id = '4701aef9-cfcc-45e2-80ec-e0f3ffdc25dc';

-- step 9: add a custom metadata to the forwarded message
UPDATE public.messages
SET metadata = jsonb_set(
    COALESCE(metadata, '{}'), 
    '{is_important}', 
    'true',
    true
)
WHERE id = '4701aef9-cfcc-45e2-80ec-e0f3ffdc25dc';


-- step 10: reply to the forwarded message
INSERT INTO public.messages (channel_id, user_id, content, reply_to_message_id)
VALUES(
    '70ceab8b-2cf6-4004-8561-219de9b11ec2', -- Channel: movie-night
    'c2e3e9e7-d0e8-4960-9b05-d263deb2722f', -- User: Lisa
    'I am! Cant wait to watch it.', -- Content
    '4701aef9-cfcc-45e2-80ec-e0f3ffdc25dc' -- original message id
);


/*
    -----------------------------------------
    9. Mention @user in Messages
       Expectation: Jack should receive a notification from Philip in the game-boy channel.
    -----------------------------------------
*/
insert into public.messages (id, content, channel_id, user_id)
values
(
    '61db563c-a4fa-4ec1-bff5-543e620c9ec2', -- ID
    'Hey, @jack would you please call me?',
    '7ea75977-9bc0-4008-b5b8-13c56d16a588', -- chanel: game-boy
    '35477c6b-f9a0-4bad-af0b-545c99b33fae' -- user: philip
);


/*
    -----------------------------------------
    10. Mention @everyone in Messages
       Expectation: Philip and Jack should receive notifications from John in the openai channel.
    -----------------------------------------
*/
insert into public.messages (id, content, channel_id, user_id)
values
(
    '447d5510-741c-4aca-bd54-6f8344da89ea', -- ID
    'Hey, @everyone, lets talk about the last season of Stranger Things! I just finished watching it and I have a lot of thoughts.',
    'dc6a0f60-5260-456b-a5c7-b799cece8807', -- chanel: openai
    '5f55998b-7958-4ae3-bcb7-539c65c00884' -- user: jack
);




/*
    -----------------------------------------
    11. Update Message Content
       Expectation: All message previews, from reply to forwarded messages, channel message previews, and notification message previews should be updated.
    -----------------------------------------
*/


-- step 1: create a message
INSERT INTO public.messages (id, content, channel_id, user_id)
VALUES
(
    '5716352d-9380-49aa-9509-71e06f8b3d23', -- ID
    'Exciting news about upcoming features!', -- Content
    '4d582754-4d72-48f8-9e72-f6aa63dacada', -- Channel: netfilix
    '35477c6b-f9a0-4bad-af0b-545c99b33fae' -- User: Philip
);

-- step 2: reply to the message
INSERT INTO public.messages (channel_id, user_id, content, reply_to_message_id)
values
(
    '4d582754-4d72-48f8-9e72-f6aa63dacada', -- Channel: netfilix
    '5f55998b-7958-4ae3-bcb7-539c65c00884', -- User: Jack
    'YUP! Lets talk about it!', -- Content
    '5716352d-9380-49aa-9509-71e06f8b3d23' -- original message id
);

-- step 3: forward the message
INSERT INTO public.messages (id, channel_id, user_id, original_message_id)
values
(
    '8c6a047a-4e0f-46eb-8e7d-0f4357fabc86', -- ID
    'dc6a0f60-5260-456b-a5c7-b799cece8807', -- Channel: openai
    'dc7d6520-8408-4a8b-b628-78d5f82b8b62', -- User: Jhon
    '5716352d-9380-49aa-9509-71e06f8b3d23' -- original message id
),
(
    'bb27aacc-e31a-4664-9606-103972702dd5', -- ID
    '1292efc2-0cdc-470c-9364-ba76f19ce75d', -- Channel: tech-talk
    'c2e3e9e7-d0e8-4960-9b05-d263deb2722f', -- User: Lisa
    '5716352d-9380-49aa-9509-71e06f8b3d23' -- original message id
);

-- step 4: update the message
UPDATE public.messages
SET content = 'Exciting news about upcoming features! I am so excited to share this with you all. Stay tuned for more updates!'
WHERE id = '5716352d-9380-49aa-9509-71e06f8b3d23';



/*
    -----------------------------------------
    13. Soft Delete a Message
       Expectation: After soft deleting the pinned message, the pinned message must be deleted and related updates should occur.

    -----------------------------------------
*/

-- step 1: create two messages
INSERT INTO public.messages (id, content, channel_id, user_id)
VALUES
(
    '2ed171d6-7247-46b2-8f6f-7703cf2634bf', -- ID
    'Exciting news about upcoming features!', -- Content
    '4d582754-4d72-48f8-9e72-f6aa63dacada', -- Channel: netfilix
    '35477c6b-f9a0-4bad-af0b-545c99b33fae' -- User: Philip
),
(
    'de4b69f5-a304-4afa-80cc-89882d612d20', -- ID
    'Hows ready for releas news!?', -- Content
    '4d582754-4d72-48f8-9e72-f6aa63dacada', -- Channel: netfilix
    '35477c6b-f9a0-4bad-af0b-545c99b33fae' -- User: Philip
);

-- step 2: pinning the message
-- expect: adfter soft delete the pinned message must delete
INSERT INTO public.pinned_messages (channel_id, message_id, pinned_by)
values
(
    '4d582754-4d72-48f8-9e72-f6aa63dacada', -- Channel: netfilix
    'de4b69f5-a304-4afa-80cc-89882d612d20', -- Message: Exciting news about upcoming features!
    '35477c6b-f9a0-4bad-af0b-545c99b33fae' -- User: Philip
);


-- step 2: reply to the message
INSERT INTO public.messages (channel_id, user_id, content, reply_to_message_id)
values
(
    '4d582754-4d72-48f8-9e72-f6aa63dacada', -- Channel: netfilix
    'c2e3e9e7-d0e8-4960-9b05-d263deb2722f', -- User: lisa
    'YUP! Lets talk about it!', -- Content
    'de4b69f5-a304-4afa-80cc-89882d612d20' -- original message id
);


-- step 3: forward the message
INSERT INTO public.messages (id, channel_id, user_id, original_message_id)
values
(
    '8c6a047a-4e0f-46eb-8e7d-0f4357fabc86', -- ID
    'dc6a0f60-5260-456b-a5c7-b799cece8807', -- Channel: openai
    'dc7d6520-8408-4a8b-b628-78d5f82b8b62', -- User: Jhon
    'de4b69f5-a304-4afa-80cc-89882d612d20' -- original message id
),
(
    'bb27aacc-e31a-4664-9606-103972702dd5', -- ID
    '1292efc2-0cdc-470c-9364-ba76f19ce75d', -- Channel: tech-talk
    'c2e3e9e7-d0e8-4960-9b05-d263deb2722f', -- User: Lisa
    'de4b69f5-a304-4afa-80cc-89882d612d20' -- original message id
);

-- step 4: soft delete the message
UPDATE public.messages
SET deleted_at = now()
WHERE id = 'de4b69f5-a304-4afa-80cc-89882d612d20';


-- leave must be delete not soft delete!
-- Test notificaiton for mute user or channle

