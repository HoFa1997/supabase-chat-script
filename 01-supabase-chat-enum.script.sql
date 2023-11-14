-- Custom types

-- Define various permissions for app functionality.
-- This includes creating, deleting, and editing channels and messages,
-- as well as viewing, editing, and deleting users, and creating, editing, and deleting roles.
create type public.app_permission as enum (
  'channels.create', 'channels.delete', 'channels.edit',
  'messages.create', 'messages.delete', 'messages.edit',
  'users.view', 'users.edit', 'users.delete',
  'roles.create', 'roles.edit', 'roles.delete'
);

-- Define roles within the app.
-- 'admin' has the highest level of access,
-- 'moderator' has limited administrative capabilities,
-- 'member' is a standard user role,
-- 'guest' has restricted access, usually for temporary or limited users.
create type public.app_role as enum ('admin', 'moderator', 'member', 'guest');

-- Define the status of the users.
-- 'ONLINE' indicates the user is actively using the app,
-- 'OFFLINE' indicates the user is not currently using the app,
-- 'AWAY' signifies the user is temporarily away,
-- 'BUSY' shows the user is occupied and might not respond promptly,
-- 'INVISIBLE' allows users to use the app without appearing online.
create type public.user_status as enum ('ONLINE', 'OFFLINE', 'AWAY', 'BUSY', 'INVISIBLE');

-- Define the types of messages that can be sent.
-- 'text' is a standard text message,
-- 'image' is a message with an image attachment,
-- 'video' is a message with a video attachment,
-- 'audio' is a message with an audio attachment.
create type public.message_type as enum ('text', 'image', 'video', 'audio', 'link', 'giphy', 'file');


-- NOTE: The following types are not currently used in the schema.
-- Define the types of notifications that can be sent.
create type public.notification_type as enum (
  'message', 'channel_invite', 'mention', 'reply', 'thread_update',
  'channel_update', 'member_join', 'member_leave', 'user_activity',
  'task_assignment', 'event_reminder', 'system_update', 'security_alert',
  'like_reaction', 'feedback_request', 'performance_insight'
);