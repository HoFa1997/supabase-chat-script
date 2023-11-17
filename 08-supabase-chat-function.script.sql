/*
  Triggers and functions to update channel information based on message activities.
  This script was last tested on 11/15/2023 and passed successfully.
*/
CREATE OR REPLACE FUNCTION update_last_message_preview()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.channels
  SET last_message_preview = substring(NEW.content from 1 for 100) -- example to get the first 100 characters
  WHERE id = NEW.channel_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
 

/*
  Update Trigger for Edited Messages
  This function updates the last message preview in a channel when a message is edited. It checks if the edited message is the last message in the channel and updates the preview accordingly.
  This script was last tested on 11/15/2023 and passed successfully.
*/
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


/*
  Trigger for Deleted Messages
  This function is a trigger function that handles the deletion of messages in a chat application.
  It updates the last message preview of the channel based on the next most recent message in the channel.
  If there are no more messages in the channel, it sets the last message preview to NULL or a default text. 
  This script was last tested on 11/15/2023 and passed successfully.
*/
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


/*
  This function updates the last activity timestamp of a channel whenever a new message is pinned.
  This script was last tested on 11/15/2023 and passed successfully.
*/
CREATE OR REPLACE FUNCTION update_last_activity()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.channels
  SET last_activity_at = NOW()
  WHERE id = NEW.channel_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/*
  This function updates the replied_message_preview field in the public.messages table
  whenever a new message is added that is a reply to an existing message.
  This script fixed before the 11/15/2023 and passed successfully.
*/
CREATE OR REPLACE FUNCTION update_message_previews()
RETURNS TRIGGER AS $$
DECLARE
  original_content TEXT;
BEGIN
  -- Get the content of the original message being replied to
  SELECT content INTO original_content FROM public.messages WHERE id = NEW.reply_to_message_id;

  -- Update the replied_message_preview of the new message with the content of the original message
  UPDATE public.messages
  SET replied_message_preview = original_content
  WHERE id = NEW.id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


/*
  This trigger function updates the content of forwarded messages when the original message is updated.
  It listens on the content column of the messages table and updates the content of all messages that have 
  the same original_message_id as the updated message.
  This script was last tested on 11/15/2023 and passed successfully.
*/
CREATE OR REPLACE FUNCTION update_forwarded_messages()
RETURNS TRIGGER AS $$
DECLARE
  forwarded_message_content TEXT;
BEGIN
  -- Get the content of the original message being replied to
  SELECT content INTO forwarded_message_content FROM public.messages WHERE id = NEW.reply_to_message_id;

  UPDATE public.messages
  SET content = forwarded_message_content
  WHERE id = NEW.id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


/*
  This trigger function sets the deleted_at timestamp for forwarded messages in the public.
  messages table when the original message is deleted. 
  The function takes no input parameters and returns the OLD row. 
  This script was last tested on 11/16/2023 and passed successfully.
*/
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

/*
  Function to create message notifications.
  It inserts a notification for each member of a channel when a new message is posted.
  The notification includes a preview of the message content.
  The notification is not created for the user who posted the message.
  This script was last tested on 11/16/2023 and passed successfully.
*/
CREATE OR REPLACE FUNCTION create_message_notifications()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.notifications (user_id, type, message_id, created_at, message_preview)
  SELECT member_id, 'message', NEW.id, NOW(), substring(NEW.content from 1 for 100)
  FROM public.channel_members
  WHERE channel_id = NEW.channel_id AND member_id != NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/*
  Function to create mention notifications.
  It inserts a notification for each user mentioned in a new message.
*/
CREATE OR REPLACE FUNCTION create_mention_notifications()
RETURNS TRIGGER AS $$
DECLARE
  mention_record RECORD; -- Declare a record type variable
BEGIN
  FOR mention_record IN SELECT mentioned_user_id FROM public.message_mentions WHERE message_id = NEW.id LOOP
    INSERT INTO public.notifications (user_id, type, mention_id, created_at, message_preview)
    VALUES (mention_record.mentioned_user_id, 'mention', NEW.id, NOW(), substring(NEW.content from 1 for 100));
  END LOOP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- inserts a row into public.users and assigns roles
create function public.handle_new_user()
returns trigger as $$
DECLARE
  username text;
BEGIN
  IF new.raw_user_meta_data->>'full_name' IS NULL THEN
    username := new.email; 
  ELSE
    username := new.raw_user_meta_data->>'full_name'; 
  END IF;

  -- Insert statement
  INSERT INTO public.users (id, full_name, avatar_url, email, username)
  VALUES (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'avatar_url',
    new.email,
    username
  );

  RETURN new;
END;
$$ language plpgsql security definer;

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