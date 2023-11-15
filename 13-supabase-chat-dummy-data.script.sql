
-- DUMMY DATA
insert into public.users (id, username)
values
    ('8d0fd2b3-9ca7-4d9e-a95f-9e13dded323e', 'supabot'),
    ('5f55998b-7958-4ae3-bcb7-539c65c00884', 'jack'),
    ('35477c6b-f9a0-4bad-af0b-545c99b33fae', 'philip');

insert into public.channels (id, slug, created_by, description)
values
    ('4b9f0f7e-6cd5-49b6-a8c3-141ef5905959', 'public', '8d0fd2b3-9ca7-4d9e-a95f-9e13dded323e', null),
    ('27c6745d-cebd-4afd-92b0-3b9b9312381b', 'random', '8d0fd2b3-9ca7-4d9e-a95f-9e13dded323e', null),
    ('7ea75977-9bc0-4008-b5b8-13c56d16a588', 'game-boy', '35477c6b-f9a0-4bad-af0b-545c99b33fae', 'game boy, lates game awards, etc.'),
    ('4d582754-4d72-48f8-9e72-f6aa63dacada', 'netfilix', '35477c6b-f9a0-4bad-af0b-545c99b33fae', 'lets talk about netflix series');


insert into public.channel_members (channel_id, member_id)
values
    ('4b9f0f7e-6cd5-49b6-a8c3-141ef5905959', '8d0fd2b3-9ca7-4d9e-a95f-9e13dded323e'), -- public, supabot
    ('27c6745d-cebd-4afd-92b0-3b9b9312381b', '8d0fd2b3-9ca7-4d9e-a95f-9e13dded323e'), -- random, supabot
    ('7ea75977-9bc0-4008-b5b8-13c56d16a588', '5f55998b-7958-4ae3-bcb7-539c65c00884'), -- game_boy, jack
    ('4d582754-4d72-48f8-9e72-f6aa63dacada', '5f55998b-7958-4ae3-bcb7-539c65c00884'), -- game_boy, jack
    ('7ea75977-9bc0-4008-b5b8-13c56d16a588', '35477c6b-f9a0-4bad-af0b-545c99b33fae'), -- game_boy, philip
    ('4d582754-4d72-48f8-9e72-f6aa63dacada', '35477c6b-f9a0-4bad-af0b-545c99b33fae'); -- netfilix, philip

insert into public.messages (id, content, channel_id, user_id)
values
    ('84fd39d1-4467-4181-b07d-b4e9573bc8f9', 'Hello World 👋', '4b9f0f7e-6cd5-49b6-a8c3-141ef5905959', '8d0fd2b3-9ca7-4d9e-a95f-9e13dded323e'),
    ('0363b237-8a72-462c-91b5-f5ee40958cf5', 'Perfection is attained, not when there is nothing more to add, but when there is nothing left to take away.', '27c6745d-cebd-4afd-92b0-3b9b9312381b', '8d0fd2b3-9ca7-4d9e-a95f-9e13dded323e'),
    ('5de80678-2e4b-4850-ae0e-4e71afaf61bb', 'hey, whats up, what do we have for this weekend?', '4d582754-4d72-48f8-9e72-f6aa63dacada', '5f55998b-7958-4ae3-bcb7-539c65c00884'),
    ('46e33eff-3a56-4619-bb7c-07e3e96af041', 'whats up?', '4d582754-4d72-48f8-9e72-f6aa63dacada', '5f55998b-7958-4ae3-bcb7-539c65c00884'),
    ('7e84eca7-cf38-4eee-8127-847e78727ea5', 'We have new event, follow up in this link...', '7ea75977-9bc0-4008-b5b8-13c56d16a588', '35477c6b-f9a0-4bad-af0b-545c99b33fae');

insert into public.pinned_messages (channel_id, message_id, pinned_by)
values
    ('7ea75977-9bc0-4008-b5b8-13c56d16a588', '7e84eca7-cf38-4eee-8127-847e78727ea5', '35477c6b-f9a0-4bad-af0b-545c99b33fae');



insert into public.role_permissions (role, permission)
values
    ('admin', 'channels.delete'),
    ('admin', 'messages.delete'),
    ('moderator', 'messages.delete');

/* 
    Inserts a new message into the public.messages table with a reply to the first message
    this dummy data for test update_message_previews function
*/
INSERT INTO public.messages (channel_id , user_id , content , reply_to_message_id)
VALUES 
('4b9f0f7e-6cd5-49b6-a8c3-141ef5905959',
'5f55998b-7958-4ae3-bcb7-539c65c00884',
'This is a reply to the first message', 
'84fd39d1-4467-4181-b07d-b4e9573bc8f9'
);

/* 
    Inserts a new message into the public.messages table with a reply to the first message
    this dummy data for test update_forwarded_messages function
*/
INSERT INTO public.messages (channel_id, user_id, original_message_id)
VALUES 
('4b9f0f7e-6cd5-49b6-a8c3-141ef5905959', -- Channel ID
 '5f55998b-7958-4ae3-bcb7-539c65c00884', -- User ID
 '84fd39d1-4467-4181-b07d-b4e9573bc8f9'  -- ID of the original message being replied to
);