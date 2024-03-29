/*
Helper functions
*/

CREATE OR REPLACE FUNCTION truncate_content(input_content TEXT, max_length INT DEFAULT NULL) RETURNS TEXT AS $$
DECLARE
    -- Define a constant for the default max length
    DEFAULT_MAX_LENGTH CONSTANT INT := 80;
BEGIN
    -- Use the provided max_length or the default if not provided
    IF max_length IS NULL THEN
        max_length := DEFAULT_MAX_LENGTH;
    END IF;

    RETURN CASE
        WHEN LENGTH(input_content) > max_length THEN LEFT(input_content, max_length - 3) || '...'
        ELSE input_content
    END;
END;
$$ LANGUAGE plpgsql;

/*
  Function: handle_new_user
  Description: Inserts a new user row and assigns roles based on provided meta-data.
*/
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  username text;
BEGIN
  IF new.raw_user_meta_data->>'full_name' IS NULL THEN
    username := new.email; 
  ELSE
    username := new.raw_user_meta_data->>'full_name'; 
  END IF;

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
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Trigger: on_auth_user_created
-- Description: Executes handle_new_user function after a new user is created in auth.users table.
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE PROCEDURE public.handle_new_user();

/*
    -----------------------------------------
    -----------------------------------------
    1.
        Trigger: trigger_add_creator_as_admin
        Description: Trigger that invokes add_channel_creator_as_admin function
                     to add the channel creator as an admin in channel_members table 
                     after a new channel is created.
    -----------------------------------------
    -----------------------------------------
*/

-- Function: add_channel_creator_as_admin()
CREATE OR REPLACE FUNCTION add_channel_creator_as_admin() RETURNS TRIGGER AS $$
BEGIN
    -- Insert the channel creator as an admin into the channel_members table.
    -- This function is automatically triggered after a new channel is created.
    -- It ensures that the creator of the channel is immediately added as an admin member of the channel.
    INSERT INTO public.channel_members (channel_id, member_id, channel_member_role, joined_at)
    VALUES (NEW.id, NEW.created_by, 'ADMIN', NOW());

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION add_channel_creator_as_admin() IS 'Trigger function that adds the creator of a new channel as an admin in the channel_members table.';

-- Trigger: trigger_add_creator_as_admin
CREATE TRIGGER trigger_add_creator_as_admin
AFTER INSERT ON public.channels
FOR EACH ROW
EXECUTE FUNCTION add_channel_creator_as_admin();

COMMENT ON TRIGGER trigger_add_creator_as_admin ON public.channels IS 'Trigger that invokes add_channel_creator_as_admin function to add the channel creator as an admin in channel_members table after a new channel is created.';

/*
    --------------------------------------------------------
    Function: increment_unread_count_on_new_message
    Description: Increments the unread message count for each channel member when a new message is posted.
                 The count is incremented only for members who have not read messages up to the time of the new message.
    --------------------------------------------------------
*/

CREATE OR REPLACE FUNCTION increment_unread_count_on_new_message() RETURNS TRIGGER AS $$
DECLARE
    channel_member RECORD;
BEGIN
    -- Iterate through each member of the channel, excluding the sender
    FOR channel_member IN
        SELECT cm.member_id, cm.last_read_update 
        FROM public.channel_members cm 
        WHERE cm.channel_id = NEW.channel_id AND cm.member_id != NEW.user_id
    LOOP
        -- Increment unread message count if the new message was sent after the last read update
        IF NEW.created_at > channel_member.last_read_update THEN
            UPDATE public.channel_members
            SET unread_message_count = unread_message_count + 1
            WHERE channel_id = NEW.channel_id AND member_id = channel_member.member_id;
        END IF;
    END LOOP;

    RETURN NEW; -- Return the new message record
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION increment_unread_count_on_new_message() IS 'Function to increment unread message count for channel members upon the insertion of a new message, provided the message was posted after the member’s last read update.';

/*
    --------------------------------------------------------
    Trigger: increment_unread_count_after_new_message
    Description: Triggered after a new message is inserted. Calls the 
                 increment_unread_count_on_new_message function to update unread message counts
                 for members in the message's channel.
    --------------------------------------------------------
*/

CREATE TRIGGER increment_unread_count_after_new_message
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION increment_unread_count_on_new_message();

COMMENT ON TRIGGER increment_unread_count_after_new_message ON public.messages IS 'Trigger to increment unread message count for channel members in the channel_members table after a new message is posted.';




CREATE OR REPLACE FUNCTION handle_soft_delete() RETURNS TRIGGER AS $$
DECLARE
    truncated_content TEXT;
    currentMetadata JSONB;
BEGIN
    -- Set deleted_at timestamp for soft delete
    NEW.deleted_at := NOW();

    IF TG_OP = 'UPDATE' THEN
        -- Truncate content if necessary for soft deleted messages
        truncated_content := truncate_content(NEW.content);

        -- Delete pinned message
        DELETE FROM public.pinned_messages WHERE message_id = OLD.id;

        -- Delete associated notifications
        DELETE FROM public.notifications WHERE message_id = OLD.id;

        -- Update reply previews
        UPDATE public.messages
        SET replied_message_preview = 'The message has been deleted'
        WHERE reply_to_message_id = OLD.id;

        -- Update last message preview in the channel
        WITH last_msg AS (
            SELECT id, content
            FROM public.messages
            WHERE channel_id = OLD.channel_id AND deleted_at IS NULL AND id <> OLD.id
            ORDER BY created_at DESC
            LIMIT 1
        )
        UPDATE public.channels
        SET last_message_preview = truncated_content,
            last_activity_at = NOW()
        WHERE id = OLD.channel_id;

                -- Remove the reply from the metadata of the original message
        SELECT metadata INTO currentMetadata FROM public.messages
        WHERE id = NEW.reply_to_message_id;

        IF currentMetadata IS NOT NULL THEN
            -- Remove the deleted message ID from the 'replied' array
            currentMetadata := jsonb_set(currentMetadata, '{replied}', (currentMetadata->'replied') - NEW.id::text);

            -- Update the original message's metadata
            UPDATE public.messages
            SET metadata = currentMetadata
            WHERE id = NEW.reply_to_message_id;
        END IF;

        RETURN NEW;
    END IF;

    RETURN NULL; -- Should not reach here for an UPDATE trigger
END;
$$ LANGUAGE plpgsql;




CREATE TRIGGER handle_soft_delete_trigger
AFTER UPDATE OF deleted_at ON public.messages
FOR EACH ROW
EXECUTE FUNCTION handle_soft_delete();

COMMENT ON TRIGGER handle_soft_delete_trigger ON public.messages IS 'Trigger to handle additional actions on message soft-delete.';



CREATE OR REPLACE FUNCTION decrement_unread_message_count() RETURNS TRIGGER AS $$
DECLARE
    channel_member RECORD;
    notification_count INT;
    channel_id_used UUID;
BEGIN
    -- Determine whether it's a soft delete (update) or hard delete
    IF TG_OP = 'DELETE' THEN
        channel_id_used := OLD.channel_id;
    ELSE
        channel_id_used := NEW.channel_id;
    END IF;

    -- Decrement unread message count for channel members
    FOR channel_member IN SELECT * FROM public.channel_members WHERE channel_id = channel_id_used LOOP
        -- Count the notifications associated with the message for this particular user
        SELECT COUNT(*) INTO notification_count 
        FROM public.notifications 
        WHERE receiver_user_id = channel_member.member_id AND channel_id = channel_id_used AND read_at IS NULL;

        UPDATE public.channel_members
        SET unread_message_count = notification_count
        WHERE channel_id = channel_id_used AND member_id = channel_member.member_id;
    END LOOP;

    RETURN NULL; -- Return value is not used for AFTER triggers
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER decrement_unread_message_count_trigger_soft_delete
AFTER UPDATE OF deleted_at ON public.messages
FOR EACH ROW
WHEN (OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL)
EXECUTE FUNCTION decrement_unread_message_count();

CREATE TRIGGER decrement_unread_message_count_trigger_hard_delete
AFTER DELETE ON public.messages
FOR EACH ROW
EXECUTE FUNCTION decrement_unread_message_count();

/*
    --------------------------------------------------------
    Trigger Function: update_message_preview_on_edit
    Description: Updates message previews in various tables when a message's content is edited.
                Previews are truncated to 67 characters with ellipsis if longer than 70 characters.
    --------------------------------------------------------
*/

CREATE OR REPLACE FUNCTION update_message_preview_on_edit()
RETURNS TRIGGER AS $$
DECLARE
    truncated_content TEXT; -- Declaration of the variable
BEGIN

        truncated_content := truncate_content(NEW.content);


    -- Update unread notification preview
    UPDATE public.notifications
    SET message_preview = truncated_content
    WHERE message_id = NEW.id AND read_at IS NULL;


    -- Update previews for messages that are replies to the edited message
    UPDATE public.messages
    SET replied_message_preview = truncated_content
    WHERE reply_to_message_id = NEW.id;

    -- Update previews for messages that are forwards of the edited message
    UPDATE public.messages
    SET content = NEW.content
    WHERE origin_message_id = NEW.id;

    -- Update last message preview in the channel of the edited message
    IF NEW.thread_id IS NULL THEN
        UPDATE public.channels
        SET last_message_preview = truncated_content
        WHERE id = NEW.channel_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/*
    --------------------------------------------------------
    Trigger: update_message_content_on_edit_trigger
    Description: Activates upon editing the content of a message.
                 Invokes the update_message_preview_on_edit function to update related previews.
    --------------------------------------------------------
*/

CREATE TRIGGER update_message_content_on_edit_trigger
AFTER UPDATE OF content ON public.messages
FOR EACH ROW
WHEN (OLD.content IS DISTINCT FROM NEW.content)
EXECUTE FUNCTION update_message_preview_on_edit();


/*
    --------------------------------------------------------
    Trigger Function: update_message_preview_on_reply
    Description: Updates the preview of the message being replied to when a reply is posted.
    --------------------------------------------------------
*/

CREATE OR REPLACE FUNCTION update_channel_preview_on_new_message() RETURNS TRIGGER AS $$
DECLARE
    truncated_content TEXT; -- Declaration of the variable
BEGIN
    -- Check if the message is part of a thread. If it is, don't update the channel preview.
    IF NEW.thread_id IS NULL THEN
        -- Update the last message preview in the channel with the new message content
        -- Note: We can also add truncation logic here if required
        truncated_content := truncate_content(NEW.content);

        UPDATE public.channels
        SET last_message_preview = truncated_content,
            last_activity_at = NOW()
        WHERE id = NEW.channel_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_channel_preview_on_new_message() IS 'Function to update the last message preview in a channel when a new message is inserted, except for messages that are part of a thread.';


/*
    --------------------------------------------------------
    Trigger: update_channel_preview_on_new_message_trigger
    Description:  Activates after a new message is inserted.
                  Invokes the update_channel_preview_on_new_message function to update the last message preview in the channel.
    --------------------------------------------------------
*/

CREATE TRIGGER update_channel_preview_on_new_message_trigger
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION update_channel_preview_on_new_message();

COMMENT ON TRIGGER update_channel_preview_on_new_message_trigger ON public.messages IS 'Trigger to update the last message preview in the corresponding channel when a new message is inserted.';


CREATE OR REPLACE FUNCTION update_replied_message_preview()
RETURNS TRIGGER AS $$
DECLARE
    originalMessageContent TEXT;
    truncatedContent TEXT;
BEGIN
    -- Only proceed if this message is a reply
    IF NEW.reply_to_message_id IS NOT NULL THEN
        -- Retrieve the content of the original message
        SELECT content INTO originalMessageContent FROM public.messages
        WHERE id = NEW.reply_to_message_id;

        -- Update the replied_message_preview of the new message
        NEW.replied_message_preview := truncate_content(originalMessageContent) truncatedContent;
    END IF;

    -- Proceed with the insert operation
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER before_insert_reply_message_add_message_preview
BEFORE INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION update_replied_message_preview();


/*
    --------------------------------------------------------
    Trigger Function: copy_content_for_forwarded_message
    Description: Prepares a new message record before insertion when the message is a forward. 
                 It copies the content and media from the original message, resetting certain fields to ensure integrity.
    --------------------------------------------------------
*/
-- TODO: metadata for forwarded chains not good choice
CREATE OR REPLACE FUNCTION copy_content_for_forwarded_message()
RETURNS TRIGGER AS $$
DECLARE
  original_message RECORD;
  forwarding_user RECORD;
  user_details JSONB;
BEGIN
  -- Check if the message is a forward by the presence of origin_message_id
  IF NEW.origin_message_id IS NOT NULL THEN
    -- Retrieve content, media, and metadata from the original message
    SELECT content, html, medias, metadata, user_id INTO original_message 
    FROM public.messages 
    WHERE id = NEW.origin_message_id;

    -- Retrieve the forwarding user's details
    SELECT id, username, full_name, avatar_url INTO forwarding_user
    FROM public.users
    WHERE id = original_message.user_id; -- Assuming NEW.user_id is the ID of the user who is forwarding the message

    -- Prepare user details JSON object
    user_details := jsonb_build_object(
        'id', forwarding_user.id,
        'username', forwarding_user.username,
        'full_name', forwarding_user.full_name,
        'avatar_url', forwarding_user.avatar_url
    );

    -- Check if original_message.metadata has 'forwarding_chain' key
    IF original_message.metadata ? 'forwarding_chain' THEN
        -- Append the new user details to the existing array
        NEW.metadata := jsonb_set(original_message.metadata, '{forwarding_chain}', original_message.metadata->'forwarding_chain' || user_details);
    ELSE
        -- Create a new 'forwarding_chain' array with the user details
        NEW.metadata := jsonb_build_object('forwarding_chain', jsonb_build_array(user_details));
    END IF;

    -- Populate the new message record with content and media from the original
    NEW.content := original_message.content;
    NEW.medias := original_message.medias;
    NEW.html := original_message.html;

    -- Clear other fields not relevant for a forwarded message
    NEW.reactions := null;
    NEW.reply_to_message_id := null;
    NEW.replied_message_preview := null;
  END IF;

  RETURN NEW; -- Return the modified message record
END;
$$ LANGUAGE plpgsql;

/*
    --------------------------------------------------------
    Trigger: forward_message_content_before_insert_trigger
    Description: Activated before inserting a new message. It invokes copy_content_for_forwarded_message 
                 function to replicate content and media for forwarded messages, ensuring that certain fields are reset.
    --------------------------------------------------------
*/

CREATE TRIGGER forward_message_content_before_insert_trigger
BEFORE INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION copy_content_for_forwarded_message();

/*
    --------------------------------------------------------
    Trigger Function: update_channel_activity_on_pin
    Description: Updates the last activity timestamp of a channel when a message is pinned to it. 
                 This helps in tracking the latest interactions within the channel.
    --------------------------------------------------------
*/

CREATE OR REPLACE FUNCTION update_channel_activity_on_pin() RETURNS TRIGGER AS $$
BEGIN
    -- Update the last_activity_at timestamp of the channel where the message is pinned
    UPDATE public.channels
    SET last_activity_at = NOW()
    WHERE id = NEW.channel_id;

    RETURN NEW; -- Return the new pinned message record
END;
$$ LANGUAGE plpgsql;

/*
    --------------------------------------------------------
    Trigger: channel_activity_update_on_message_pin_trigger
    Description: Triggered after a message is pinned. It invokes update_channel_activity_on_pin 
                 function to refresh the channel's last activity timestamp.
    --------------------------------------------------------
*/

CREATE TRIGGER channel_activity_update_on_message_pin_trigger
AFTER INSERT ON public.pinned_messages
FOR EACH ROW
EXECUTE FUNCTION update_channel_activity_on_pin();

/*
    --------------------------------------------------------
    Trigger Function: update_replied_metadata_before_insert
    Description: Updates the metadata of the original message when a reply is posted.
                 The metadata is updated to include the ID of the new reply message.
    --------------------------------------------------------
*/

CREATE OR REPLACE FUNCTION update_replied_metadata_before_insert()
RETURNS TRIGGER AS $$
DECLARE
    currentMetadata JSONB;
BEGIN
    -- Only proceed if this message is a reply
    IF NEW.reply_to_message_id IS NOT NULL THEN

        -- Generate a new ID if not provided
        IF NEW.id IS NULL THEN
            NEW.id := uuid_generate_v4();
        END IF;

        -- Retrieve the current metadata of the original message
        SELECT metadata INTO currentMetadata FROM public.messages
        WHERE id = NEW.reply_to_message_id;

        -- Initialize metadata if null
        IF currentMetadata IS NULL THEN
            currentMetadata := '{}'::jsonb;
        END IF;

        -- Check if the 'replied' key exists, if not initialize it as an empty array
        IF NOT (currentMetadata ? 'replied') THEN
            currentMetadata := currentMetadata || jsonb_build_object('replied', '[]'::jsonb);
        END IF;

        -- Append the new message ID to the 'replied' array
        currentMetadata := jsonb_set(currentMetadata, '{replied}', (currentMetadata->'replied') || to_jsonb(NEW.id::text));

        -- Update the original message's metadata
        UPDATE public.messages
        SET metadata = currentMetadata
        WHERE id = NEW.reply_to_message_id;

    END IF;

    -- Proceed with the insert operation
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER before_insert_message
BEFORE INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION update_replied_metadata_before_insert();

-----------------------------------------

CREATE OR REPLACE FUNCTION handle_open_a_thread()
RETURNS TRIGGER AS $$
BEGIN
    NEW.is_thread_root := TRUE;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_open_a_thread_update
BEFORE UPDATE ON public.messages
FOR EACH ROW
WHEN (NEW.thread_owner_user_id IS NOT NULL)
EXECUTE FUNCTION handle_open_a_thread();

-----------------------------------------

-----------------------------------------

CREATE OR REPLACE FUNCTION handle_set_thread_depth()
RETURNS TRIGGER AS $$
DECLARE
    parent_thread_depth INT;
BEGIN
    -- Check if the new message has a thread_id and retrieve the thread_depth of the parent message
    SELECT thread_depth INTO parent_thread_depth FROM public.messages WHERE id = NEW.thread_id;

    -- Set the thread_depth of the new message if parent_thread_depth is not null
    IF parent_thread_depth IS NOT NULL THEN
        NEW.thread_depth := parent_thread_depth + 1;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_thread_depth
BEFORE INSERT ON public.messages
FOR EACH ROW
WHEN (NEW.thread_id IS NOT NULL)
EXECUTE FUNCTION handle_set_thread_depth();

-----------------------------------------

-----------------------------------------

CREATE OR REPLACE FUNCTION create_notifications_for_new_message() RETURNS TRIGGER AS $$
DECLARE
    mentioned_user_id UUID;
    channel_member RECORD;
    pattern TEXT;
    mention_found BOOLEAN := FALSE;
    is_channel_muted BOOLEAN;
    truncated_content TEXT;

BEGIN
    -- Check if notifications are muted for the channel
    SELECT mute_in_app_notifications INTO is_channel_muted FROM public.channels WHERE id = NEW.channel_id;
    IF is_channel_muted THEN
        RETURN NEW; -- Exit if notifications are muted for the channel
    END IF;

    truncated_content := truncate_content(NEW.content);

    -- Handle '@username' mention
    pattern := '@([a-zA-Z0-9_]+)';
    FOR mentioned_user_id IN
        SELECT u.id FROM public.users u
        WHERE u.username = substring(NEW.content FROM pattern)
    LOOP
        mention_found := TRUE;
        -- Check if the mentioned user has muted notifications
        IF (SELECT mute_in_app_notifications FROM public.channel_members WHERE channel_id = NEW.channel_id AND member_id = mentioned_user_id) = FALSE THEN
            INSERT INTO public.notifications (receiver_user_id, sender_user_id, type, message_id, channel_id, message_preview, created_at)
            VALUES (mentioned_user_id, NEW.user_id, 'mention', NEW.id, NEW.channel_id, truncated_content, NOW());
        END IF;
    END LOOP;

    -- Handle '@everyone' mention, but exclude the sender
    IF NEW.content LIKE '%@everyone%' THEN
        mention_found := TRUE;
        FOR channel_member IN SELECT cm.member_id FROM public.channel_members cm WHERE cm.channel_id = NEW.channel_id AND cm.member_id != NEW.user_id LOOP
            -- Check if the channel member has muted notifications
            IF (SELECT mute_in_app_notifications FROM public.channel_members WHERE channel_id = NEW.channel_id AND member_id = channel_member.member_id) = FALSE THEN
                INSERT INTO public.notifications (receiver_user_id, sender_user_id, type, message_id, channel_id, message_preview, created_at)
                VALUES (channel_member.member_id, NEW.user_id, 'channel_event', NEW.id, NEW.channel_id, truncated_content, NOW());
            END IF;
        END LOOP;
    END IF;


    -- If no mentions (like '@username' or '@everyone') are found in the message,
    -- then this block creates notifications for channel members. Two types of notifications are created:
    -- 1. 'reply' type for the user who is the owner of the original message being replied to.
    -- 2. 'message' type for all other channel members.
    -- These notifications are only created for channel members who have not muted in-app notifications
    -- and who are not the sender of the new message.
    IF NOT mention_found THEN
        INSERT INTO public.notifications (receiver_user_id, sender_user_id, type, message_id, channel_id, message_preview, created_at)
        SELECT 
            cm.member_id, 
            NEW.user_id,
            CASE 
                WHEN NEW.thread_id IS NOT NULL THEN 'thread_message'::notification_category
                WHEN NEW.reply_to_message_id IS NOT NULL AND m.user_id = cm.member_id THEN 'reply'::notification_category
                ELSE 'message'::notification_category
            END, 
            NEW.id, 
            NEW.channel_id, 
            truncated_content, 
            NOW()
        FROM public.channel_members cm
        LEFT JOIN public.messages m ON m.id = NEW.reply_to_message_id
        WHERE cm.channel_id = NEW.channel_id AND cm.member_id != NEW.user_id AND cm.mute_in_app_notifications = FALSE;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_on_new_message_for_notifications
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION create_notifications_for_new_message();

-----------------------------------------

CREATE OR REPLACE FUNCTION create_notifications_for_new_unique_reactions() RETURNS TRIGGER AS $$
DECLARE
    reaction_key TEXT;
    new_reaction_entry JSONB;
    reaction_exists BOOLEAN;
BEGIN
    -- Loop through each reaction type key in the updated reactions JSONB
    FOR reaction_key IN SELECT jsonb_object_keys(NEW.reactions)
    LOOP
        -- Loop through each JSON object in the new reactions array for this key
        FOR new_reaction_entry IN SELECT jsonb_array_elements(NEW.reactions -> reaction_key)
        LOOP
            -- Assume the reaction is new until found in the old reactions
            reaction_exists := FALSE;

            -- Check if this reaction entry is already in the old reactions
            IF OLD.reactions ? reaction_key THEN
                reaction_exists := EXISTS (
                    SELECT 1 
                    FROM jsonb_array_elements(OLD.reactions -> reaction_key) AS old_entry
                    WHERE (old_entry ->> 'user_id') = (new_reaction_entry ->> 'user_id')
                );
            END IF;

            -- If the reaction is new, create a notification
            IF NOT reaction_exists THEN
                INSERT INTO public.notifications (receiver_user_id, sender_user_id, type, message_id, channel_id, message_preview, created_at)
                VALUES (OLD.user_id, NEW.user_id, 'reaction', NEW.id, NEW.channel_id, truncate_content(NEW.content), NOW());
            END IF;
        END LOOP;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_on_reaction_update_for_notifications
AFTER UPDATE OF reactions ON public.messages
FOR EACH ROW
WHEN (OLD.reactions IS DISTINCT FROM NEW.reactions)
EXECUTE FUNCTION create_notifications_for_new_unique_reactions();

-----------------------------------------

CREATE OR REPLACE FUNCTION update_edited_at() RETURNS TRIGGER AS $$
BEGIN
    -- Check if the content or html column has been updated
    IF OLD.content IS DISTINCT FROM NEW.content OR OLD.html IS DISTINCT FROM NEW.html THEN
        -- Update the edited_at timestamp
        NEW.edited_at := NOW();
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_update_edited_at
BEFORE UPDATE OF content, html ON public.messages
FOR EACH ROW
EXECUTE FUNCTION update_edited_at();

-----------------------------------------

-- Function to update message metadata
CREATE OR REPLACE FUNCTION update_message_metadata_on_pin()
RETURNS TRIGGER AS $$
DECLARE
    current_metadata JSONB;
    message_content TEXT;
BEGIN
    -- Retrieve current metadata and content from the messages table for the given message_id
    SELECT metadata, content INTO current_metadata, message_content FROM public.messages WHERE id = NEW.message_id;

    -- Check if metadata is null and initialize it if necessary
    IF current_metadata IS NULL THEN
        current_metadata := '{}'::JSONB;
    END IF;

    -- Update the metadata with "pinned": true
    current_metadata := jsonb_set(current_metadata, '{pinned}', 'true');

    -- Update the messages table with new metadata
    UPDATE public.messages SET metadata = current_metadata WHERE id = NEW.message_id;

    -- Set the content of the pinned message
    NEW.content :=  truncate_content(message_content) ;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Trigger on the pinned_messages table
CREATE TRIGGER trigger_update_message_on_pin
BEFORE INSERT ON public.pinned_messages
FOR EACH ROW EXECUTE FUNCTION update_message_metadata_on_pin();

-----------------------------------------

-- Function to update message metadata when a pinned message is deleted
CREATE OR REPLACE FUNCTION update_message_metadata_on_unpin()
RETURNS TRIGGER AS $$
DECLARE
    current_metadata JSONB;
BEGIN
    -- Retrieve current metadata from the messages table for the given message_id
    SELECT metadata INTO current_metadata FROM public.messages WHERE id = OLD.message_id;

    -- Check if metadata is null and initialize it if necessary
    IF current_metadata IS NULL THEN
        current_metadata := '{}'::JSONB;
    END IF;

    -- Update the metadata with "pinned": false
    current_metadata := jsonb_set(current_metadata, '{pinned}', 'false');

    -- Update the messages table
    UPDATE public.messages SET metadata = current_metadata WHERE id = OLD.message_id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Trigger on the pinned_messages table for deletion
CREATE TRIGGER trigger_update_message_on_unpin
AFTER DELETE ON public.pinned_messages
FOR EACH ROW EXECUTE FUNCTION update_message_metadata_on_unpin();



CREATE OR REPLACE FUNCTION get_channel_aggregate_data(
    input_channel_id UUID,
    message_limit INT DEFAULT 20 -- New parameter with default value
)
RETURNS TABLE(
    channel_info JSONB,
    last_messages JSONB,
    member_count INT,
    pinned_messages JSONB,
    user_profile JSONB,
    is_user_channel_member BOOLEAN,
    channel_member_info JSONB
) AS $$
DECLARE
    channel_result JSONB;
    messages_result JSONB;
    members_result INT;
    pinned_result JSONB;
    user_data_result JSONB;
    is_member_result BOOLEAN;
    channel_member_info_result JSONB;
BEGIN

    -- Query for channel information
    SELECT json_build_object(
               'id', c.id,
               'slug', c.slug,
               'name', c.name,
               'created_by', c.created_by,
               'description', c.description,
               'member_limit', c.member_limit,
               'is_avatar_set', c.is_avatar_set,
               'allow_emoji_reactions', c.allow_emoji_reactions,
               'mute_in_app_notifications', c.mute_in_app_notifications,
               'type', c.type,
               'metadata', c.metadata
           ) INTO channel_result
    FROM public.channels c
    WHERE c.id = input_channel_id;

    -- Query for the last 10 messages with user details, including replied message details
    SELECT json_agg(t) INTO messages_result
    FROM (
        SELECT m.*,
            json_build_object(
                'id', u.id, 
                'username', u.username, 
                'fullname', u.full_name, 
                'avatar_url', u.avatar_url
            ) AS user_details,
            CASE
                WHEN m.reply_to_message_id IS NOT NULL THEN
                    (SELECT json_build_object(
                            'message', json_build_object(
                                'id', rm.id,
                                'created_at', rm.created_at
                            ),
                            'user', json_build_object(
                                'id', ru.id,
                                'username', ru.username,
                                'fullname', ru.full_name,
                                'avatar_url', ru.avatar_url
                            )
                        ) FROM public.messages rm
                        LEFT JOIN public.users ru ON rm.user_id = ru.id
                        WHERE rm.id = m.reply_to_message_id)
                ELSE NULL
            END AS replied_message_details
        FROM public.messages m
        LEFT JOIN public.users u ON m.user_id = u.id
        WHERE m.channel_id = input_channel_id AND m.deleted_at IS NULL
        ORDER BY m.created_at DESC 
        LIMIT message_limit
    ) t;

    -- Query for the count of channel members
    SELECT COUNT(*) INTO members_result
    FROM public.channel_members 
    WHERE channel_id = input_channel_id;

    -- Query for the pinned messages
    SELECT json_agg(pm) INTO pinned_result
    FROM public.pinned_messages pm
    JOIN public.messages m ON pm.message_id = m.id
    WHERE pm.channel_id = input_channel_id;

    -- Query for the user data using auth.uid()
    SELECT json_build_object(
               'id', u.id,
               'username', u.username,
               'full_name', u.full_name,
               'status', u.status,
               'avatar_url', u.avatar_url,
               'email', u.email,
               'website', u.website,
               'description', u.description
           ) INTO user_data_result
    FROM public.users u
    WHERE u.id = auth.uid();

    -- Attempt to get channel member details
    SELECT json_build_object(
            'last_read_message_id', cm.last_read_message_id,
            'last_read_update', cm.last_read_update,
            'joined_at', cm.joined_at,
            'left_at', cm.left_at,
            'mute_in_app_notifications', cm.mute_in_app_notifications,
            'channel_member_role', cm.channel_member_role,
            'unread_message_count', cm.unread_message_count
        )
    INTO channel_member_info_result
    FROM public.channel_members cm
    WHERE cm.channel_id = input_channel_id AND cm.member_id = auth.uid();

    -- Set is_member_result based on whether channel_member_info_result is null
    is_member_result := (channel_member_info_result IS NOT NULL);

    -- Return the results including the user data
    RETURN QUERY SELECT channel_result, messages_result, members_result, pinned_result, user_data_result, is_member_result, channel_member_info_result;
END;
$$ LANGUAGE plpgsql;

-- Test
-- SELECT * FROM get_channel_aggregate_data('99634205-5238-4ffc-90ec-c64be3ad25cf');


CREATE OR REPLACE FUNCTION get_channel_messages_paginated(
    input_channel_id UUID,
    page INT,
    page_size INT DEFAULT 20 
)
RETURNS TABLE(
    messages JSONB
) AS $$
DECLARE
    message_offset INT; -- Renamed 'offset' to 'message_offset' to avoid keyword conflict
BEGIN
    -- Calculate the message_offset based on the page number and page size
    message_offset := (page - 1) * page_size;

    -- Query to fetch messages with pagination
    SELECT json_agg(t) INTO messages
    FROM (
        SELECT m.*,
            json_build_object(
                'id', u.id, 
                'username', u.username, 
                'fullname', u.full_name, 
                'avatar_url', u.avatar_url
            ) AS user_details,
            CASE
                WHEN m.reply_to_message_id IS NOT NULL THEN
                    (SELECT json_build_object(
                            'message', json_build_object(
                                'id', rm.id,
                                'created_at', rm.created_at
                            ),
                            'user', json_build_object(
                                'id', ru.id,
                                'username', ru.username,
                                'fullname', ru.full_name,
                                'avatar_url', ru.avatar_url
                            )
                        ) FROM public.messages rm
                        LEFT JOIN public.users ru ON rm.user_id = ru.id
                        WHERE rm.id = m.reply_to_message_id)
                ELSE NULL
            END AS replied_message_details
        FROM public.messages m
        LEFT JOIN public.users u ON m.user_id = u.id
        WHERE m.channel_id = input_channel_id AND m.deleted_at IS NULL
        ORDER BY m.created_at DESC 
        LIMIT page_size OFFSET message_offset
    ) t;

    RETURN QUERY SELECT messages;
END;
$$ LANGUAGE plpgsql;


-- TEST
--- SELECT * FROM get_channel_messages_paginated('<channel_id>', 2, 10);
