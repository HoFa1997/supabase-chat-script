-- Index for optimizing queries filtering or sorting by username.
CREATE INDEX idx_users_username ON public.users (username);


-- Index definitions to optimize query performance on frequently accessed columns.
CREATE INDEX idx_messages_channel_id ON public.messages (channel_id);
CREATE INDEX idx_messages_user_id ON public.messages (user_id);
CREATE INDEX idx_messages_inserted_at ON public.messages (inserted_at);
CREATE INDEX idx_messages_type ON public.messages (type);
CREATE INDEX idx_messages_channel_id_inserted_at ON public.messages (channel_id, inserted_at);
CREATE INDEX idx_channels_slug ON public.channels (slug);
CREATE INDEX idx_channels_created_by ON public.channels (created_by);
CREATE INDEX idx_channels_archived_activity ON public.channels (is_archived, last_activity_at);


-- Index definitions to optimize query performance on frequently accessed columns.
CREATE INDEX idx_pinned_messages_channel_id ON public.pinned_messages (channel_id);
CREATE INDEX idx_pinned_messages_message_id ON public.pinned_messages (message_id);


CREATE INDEX idx_user_roles_user_id ON public.user_roles (user_id);
CREATE INDEX idx_role_permissions_role ON public.role_permissions (role);


CREATE INDEX idx_channel_members_channel_id ON public.channel_members (channel_id);
CREATE INDEX idx_channel_members_member_id ON public.channel_members (member_id);

CREATE INDEX idx_notifications_user_id ON public.notifications (user_id);
CREATE INDEX idx_notifications_created_at ON public.notifications (created_at);