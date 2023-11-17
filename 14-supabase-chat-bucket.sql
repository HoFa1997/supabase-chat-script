/*
    This code sets up storage for user avatars in a Supabase chat application.
    It creates a bucket named 'user_avatars' and defines three policies for the bucket's objects.
    - "Avatar images are publicly accessible." policy allows anyone to select objects from the bucket.
    - "Anyone can upload an avatar." policy allows anyone to insert objects into the bucket.
    - "Anyone can update their own avatar." policy allows users to update their own avatar in the bucket.
*/
insert into storage.buckets (id, name)
    values ('user_avatars', 'user_avatars');

create policy "User Avatar are publicly accessible." on storage.objects
for select using (bucket_id = 'user_avatars');

create policy "Anyone can upload an User Avatar." on storage.objects
for insert with check (bucket_id = 'user_avatars');

create policy "Anyone can update their own User Avatar." on storage.objects
for update using (auth.uid() = owner) with check (bucket_id = 'user_avatars');


/*
    This SQL code is used to insert a new record into the "storage.buckets" table,
    create three policies for the "storage.objects" table related to the "channel_avatars" bucket,
    and define the conditions for selecting, inserting, and updating objects in the bucket.
    The first policy allows public access to select objects in the "channel_avatars" bucket.
    The second policy allows anyone to insert objects into the "channel_avatars" bucket.
    The third policy allows anyone to update their own channel in the "channel_avatars" bucket,
    based on the condition that the authenticated user's ID matches the owner of the object.
*/
insert into storage.buckets (id, name)
  values ('channel_avatars', 'channel_avatars');

create policy "Channel Avatar images are publicly accessible." on storage.objects
for select using (bucket_id = 'channel_avatars');

create policy "Anyone can upload an Channel Avatar." on storage.objects
for insert with check (bucket_id = 'channel_avatars');

create policy "Anyone can update their own Channel Avatar." on storage.objects
for update using (auth.uid() = owner) with check (bucket_id = 'channel_avatars');


/*
    This SQL code is used to insert a new row into the "storage.buckets" table,
    create three policies for the "storage.objects" table in order to manage access control for media files.

    The first policy, "Avatar images are publicly accessible.", allows users to select objects from the "storage.objects" table
    only if the bucket_id is set to 'media'.

    The second policy, "Anyone can upload an avatar.", allows users to insert new objects into the "storage.objects" table
    only if the bucket_id is set to 'media'.

    The third policy, "Anyone can update their own media.", allows users to update objects in the "storage.objects" table
    only if the authenticated user's ID matches the owner column value and the bucket_id is set to 'media'.
*/
insert into storage.buckets (id, name)
  values ('media', 'media');

create policy "media are publicly accessible." on storage.objects
for select using (bucket_id = 'media');

create policy "Anyone can upload an media." on storage.objects
for insert with check (bucket_id = 'media');

create policy "Anyone can update their media." on storage.objects
for update using (auth.uid() = owner) with check (bucket_id = 'media');
