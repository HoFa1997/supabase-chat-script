-- Secure the tables
alter table public.users enable row level security;
alter table public.channels enable row level security;
alter table public.messages enable row level security;
alter table public.user_roles enable row level security;
alter table public.role_permissions enable row level security;
create policy "Allow logged-in read access" on public.users for select using ( auth.role() = 'authenticated' );
create policy "Allow individual insert access" on public.users for insert with check ( auth.uid() = id );
create policy "Allow individual update access" on public.users for update using ( auth.uid() = id );
create policy "Allow logged-in read access" on public.channels for select using ( auth.role() = 'authenticated' );
create policy "Allow individual insert access" on public.channels for insert with check ( auth.uid() = created_by );
create policy "Allow individual delete access" on public.channels for delete using ( auth.uid() = created_by );
create policy "Allow authorized delete access" on public.channels for delete using ( authorize('channels.delete', auth.uid()) );
create policy "Allow logged-in read access" on public.messages for select using ( auth.role() = 'authenticated' );
create policy "Allow individual insert access" on public.messages for insert with check ( auth.uid() = user_id );
create policy "Allow individual update access" on public.messages for update using ( auth.uid() = user_id );
create policy "Allow individual delete access" on public.messages for delete using ( auth.uid() = user_id );
create policy "Allow authorized delete access" on public.messages for delete using ( authorize('messages.delete', auth.uid()) );
create policy "Allow individual read access" on public.user_roles for select using ( auth.uid() = user_id );