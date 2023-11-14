-- Triggers and functions to update channel information based on message activities.

CREATE OR REPLACE FUNCTION update_last_message_preview()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.channels
  SET last_message_preview = substring(NEW.content from 1 for 100) -- example to get the first 100 characters
  WHERE id = NEW.channel_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--- Update Trigger for Edited Messages
CREATE OR REPLACE FUNCTION handle_message_update()
RETURNS TRIGGER AS $$
DECLARE
  last_message RECORD;
BEGIN
  -- Get the last message in the channel
  SELECT * INTO last_message FROM public.messages
  WHERE channel_id = NEW.channel_id
  ORDER BY inserted_at DESC
  LIMIT 1;

  -- Check if the updated message is the last message
  IF last_message.id = NEW.id THEN
    UPDATE public.channels
    SET last_message_preview = substring(NEW.content from 1 for 100)
    WHERE id = NEW.channel_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

---- Trigger for Deleted Messages
CREATE OR REPLACE FUNCTION handle_message_delete()
RETURNS TRIGGER AS $$
DECLARE
  next_message RECORD;
BEGIN
  -- Get the next most recent message in the channel
  SELECT * INTO next_message FROM public.messages
  WHERE channel_id = OLD.channel_id
  ORDER BY inserted_at DESC
  LIMIT 1;

  -- Update the last message preview based on the next most recent message
  UPDATE public.channels
  SET last_message_preview = CASE
    WHEN next_message IS NOT NULL THEN substring(next_message.content from 1 for 100)
    ELSE NULL -- Or your default text like 'No messages in this channel'
  END
  WHERE id = OLD.channel_id;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- PINNED MESSAGES TRIGGER TO UPDATE LAST ACTIVITY
CREATE OR REPLACE FUNCTION update_last_activity()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.channels
  SET last_activity_at = NOW()
  WHERE id = NEW.channel_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER TO UPDATE replied_message_preview
CREATE OR REPLACE FUNCTION update_message_previews()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.messages
  SET replied_message_preview = NEW.content -- Or whatever content should be previewed
  WHERE reply_to_message_id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- TRIGGER TO UPDATE forwarded messages, listen on the content column
CREATE OR REPLACE FUNCTION update_forwarded_messages()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.messages
  SET content = NEW.content
  WHERE original_message_id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- TRIGGER TO SOFT DELETE forwarded messages
CREATE OR REPLACE FUNCTION soft_delete_forwarded_messages()
RETURNS TRIGGER AS $$
BEGIN
  -- Set the deleted_at timestamp for forwarded messages
  UPDATE public.messages
  SET deleted_at = now()
  WHERE original_message_id = OLD.id AND deleted_at IS NULL;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;


-- authorize with role-based access control (RBAC)
create function public.authorize(
  requested_permission app_permission,
  user_id uuid
)
returns boolean as $$
declare
  bind_permissions int;
begin
  select count(*)
  from public.role_permissions
  inner join public.user_roles on role_permissions.role = user_roles.role
  where role_permissions.permission = authorize.requested_permission
    and user_roles.user_id = authorize.user_id
  into bind_permissions;

  return bind_permissions > 0;
end;
$$ language plpgsql security definer;

-- Function to create mention notifications.
-- It inserts a notification for each user mentioned in a new message.
CREATE OR REPLACE FUNCTION create_mention_notifications()
RETURNS TRIGGER AS $$
DECLARE
  mention_record RECORD; -- Declare a record type variable
BEGIN
  FOR mention_record IN SELECT mentioned_user_id FROM public.message_mentions WHERE message_id = NEW.id LOOP
    INSERT INTO public.notifications (user_id, type, ref_id, created_at, message_preview)
    VALUES (mention_record.mentioned_user_id, 'mention', NEW.id, NOW(), substring(NEW.content from 1 for 100));
  END LOOP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Function to create message notifications.
-- It inserts a notification for each member of a channel when a new message is posted.
-- The notification includes a preview of the message content.
-- The notification is not created for the user who posted the message.
CREATE OR REPLACE FUNCTION create_message_notifications()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.notifications (user_id, type, ref_id, created_at, message_preview)
  SELECT member_id, 'message', NEW.id, NOW(), substring(NEW.content from 1 for 100)
  FROM public.channel_members
  WHERE channel_id = NEW.channel_id AND member_id != NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- inserts a row into public.users and assigns roles
create function public.handle_new_user()
returns trigger as $$
declare is_admin boolean;
begin
  insert into public.users (id, username)
  values (new.id, new.email);

  select count(*) = 1 from auth.users into is_admin;

  if position('+supaadmin@' in new.email) > 0 then
    insert into public.user_roles (user_id, role) values (new.id, 'admin');
  elsif position('+supamod@' in new.email) > 0 then
    insert into public.user_roles (user_id, role) values (new.id, 'moderator');
  end if;

  return new;
end;
$$ language plpgsql security definer;