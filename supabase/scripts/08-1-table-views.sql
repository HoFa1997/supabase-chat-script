-- We use regular views instead of materialized views.
-- Later for performance improvement, we can change them to materialized views.
-- But it will require more time to test, maintain, and deploy.
-- So for now, we will use regular views.

CREATE OR REPLACE VIEW public.view_pinned_messages AS
SELECT
    pm.id AS pinned_message_id,
    pm.channel_id,
    pm.pinned_at,
    pm.pinned_by,
    m.content,
    m.html,
    m.medias,
    m.reactions,
    m.metadata,
    m.created_at AS message_created_at,
    m.updated_at AS message_updated_at,
    m.user_id AS message_user_id,
    m.type AS message_type,
    u.username AS pinner_username,
    u.full_name AS pinner_full_name,
    u.avatar_url AS pinner_avatar_url
FROM
    public.pinned_messages pm
    JOIN public.messages m ON pm.message_id = m.id
    JOIN public.users u ON pm.pinned_by = u.id;

-- If you need member_count alive run this query
CREATE OR REPLACE VIEW public.view_channels AS
SELECT
    c.id AS channel_id,
    c.slug,
    c.name,
    c.created_at,
    c.created_by,
    c.description,
    c.member_limit,
    c.last_activity_at,
    c.last_message_preview,
    c.is_avatar_set,
    c.allow_emoji_reactions,
    c.mute_in_app_notifications,
    c.type AS channel_type,
    c.metadata,
    COUNT(cm.member_id) AS member_count
FROM
    public.channels c
    LEFT JOIN public.channel_members cm ON c.id = cm.channel_id
GROUP BY
    c.id;
