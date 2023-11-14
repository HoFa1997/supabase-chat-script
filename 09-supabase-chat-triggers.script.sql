-- Triggers and functions to update channel information based on message activities.
CREATE TRIGGER trigger_update_last_message_preview
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION update_last_message_preview();


--- Update Trigger for Edited Messages
CREATE TRIGGER trigger_handle_message_update
AFTER UPDATE ON public.messages
FOR EACH ROW
WHEN (OLD.content IS DISTINCT FROM NEW.content)
EXECUTE FUNCTION handle_message_update();

---- Trigger for Deleted Messages
CREATE TRIGGER trigger_handle_message_delete
AFTER DELETE ON public.messages
FOR EACH ROW
EXECUTE FUNCTION handle_message_delete();


-- Triggers to update last activity in channels based on message and pinned message activities.
-- PINNED MESSAGES TRIGGER TO UPDATE LAST ACTIVITY
CREATE TRIGGER trigger_update_last_activity
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION update_last_activity();

CREATE TRIGGER trigger_update_last_activity_pinned
AFTER INSERT OR DELETE ON public.pinned_messages
FOR EACH ROW
EXECUTE FUNCTION update_last_activity();



-- Triggers and functions for handling message updates, replies, and soft deletes.
-- (Triggers and function definitions remain the same)
CREATE TRIGGER update_replied_previews
BEFORE UPDATE ON public.messages
FOR EACH ROW
EXECUTE FUNCTION update_message_previews();

CREATE TRIGGER update_original_message
AFTER UPDATE ON public.messages
FOR EACH ROW
WHEN (OLD.content IS DISTINCT FROM NEW.content)
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