/*
  This script creates a trigger that updates channel information based on message activities.
  Specifically, it creates a trigger named "trigger_update_last_message_preview" that executes the function "update_last_message_preview" after each insertion into the "public.messages" table.
  The purpose of this trigger is to update the last message preview for the channel associated with the inserted message.
  This script was last tested on 11/15/2023 and passed successfully.
*/
CREATE TRIGGER trigger_update_last_message_preview
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION update_last_message_preview();

/*
  This trigger is used to handle edited messages in the public.messages table.
  It executes the handle_message_update() function when a message is updated and its content is changed.
  This script was last tested on 11/15/2023 and passed successfully.
*/
CREATE TRIGGER trigger_handle_message_update
AFTER UPDATE ON public.messages
FOR EACH ROW
WHEN (OLD.content IS DISTINCT FROM NEW.content)
EXECUTE FUNCTION handle_message_update();

/*
  This trigger is used to handle deleted messages in the public.messages table.
  It executes the handle_message_delete() function for each deleted row.
  This script was last tested on 11/15/2023 and passed successfully.
*/
CREATE TRIGGER trigger_handle_message_delete
AFTER DELETE ON public.messages
FOR EACH ROW
EXECUTE FUNCTION handle_message_delete();

/*
  Triggers to update last activity in channels based on message and pinned message activities.
  This script creates two triggers that update the last activity in channels based on message and pinned message activities.
  The first trigger, "trigger_update_last_activity", is fired after a new message is inserted into the "public.messages" table.
  The second trigger, "trigger_update_last_activity_pinned",
  is fired after a new pinned message is inserted or deleted from the "public.pinned_messages" table.
  Both triggers execute the same function, "update_last_activity()".  
  This script was last tested on 11/15/2023 and passed successfully.
*/
CREATE TRIGGER trigger_update_last_activity
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION update_last_activity();

CREATE TRIGGER trigger_update_last_activity_pinned
AFTER INSERT OR DELETE ON public.pinned_messages
FOR EACH ROW
EXECUTE FUNCTION update_last_activity();



/*
  This code creates a trigger named "update_replied_previews" that executes the function "update_message_previews"before
  each update on the "public.messages" table. The purpose of this trigger is to update the message previews when a message is updated.
  This script was last tested on 11/15/2023 and passed successfully.
*/
CREATE TRIGGER trigger_update_replied_previews
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION update_message_previews();

/*
  This trigger updates forwarded messages when the content of a message is updated.
  This script was last tested on 11/15/2023 and passed successfully.
*/
CREATE TRIGGER trigger_update_original_message
AFTER INSERT ON public.messages
FOR EACH ROW
WHEN (NEW.original_message_id IS NOT NULL)
EXECUTE FUNCTION update_forwarded_messages();

CREATE TRIGGER soft_delete_original_message
AFTER DELETE ON public.messages
FOR EACH ROW
EXECUTE FUNCTION soft_delete_forwarded_messages();

CREATE TRIGGER trigger_create_message_notifications
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION create_message_notifications();

CREATE TRIGGER trigger_create_mention_notifications
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION create_mention_notifications();

-- trigger the function every time a user is created
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
/**
 * REALTIME SUBSCRIPTIONS
 * Only allow realtime listening on public tables.
 */
begin;
  -- remove the realtime publication
  drop publication if exists supabase_realtime;
  -- re-create the publication but don't enable it for any tables
  create publication supabase_realtime;
commit;