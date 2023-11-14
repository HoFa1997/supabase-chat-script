-- Send "previous data" on change
alter table public.users replica identity full;
alter table public.channels replica identity full;
alter table public.messages replica identity full;

-- add tables to the publication
alter publication supabase_realtime add table public.users;
alter publication supabase_realtime add table public.channels;
alter publication supabase_realtime add table public.messages;