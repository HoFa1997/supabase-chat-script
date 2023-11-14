

CREATE TABLE public.message_mentions (
  id            UUID DEFAULT uuid_generate_v4() NOT NULL PRIMARY KEY,
  message_id    UUID REFERENCES public.messages(id) ON DELETE CASCADE,
  mentioned_user_id UUID REFERENCES public.users(id) ON DELETE CASCADE
);