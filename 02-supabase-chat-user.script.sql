-- USERS

-- This table stores the primary user information for each user in the application.
-- It includes a unique identifier, a username, and the user's current status,
-- along with timestamps for creation and last update.
create table public.users (
  id          uuid not null primary key, -- Unique identifier for each user, linked to the Supabase Auth user ID.
  username    text not null unique,      -- The username chosen by the user. Ensured to be unique.
  status      user_status default 'OFFLINE'::public.user_status  -- Current status of the user, defaults to 'OFFLINE'.
);

comment on table public.users is 'Profile data for each user.';
comment on column public.users.id is 'References the internal Supabase Auth user ID.';
comment on column public.users.username is 'Unique username for each user.';
comment on column public.users.status is 'Current online/offline status of the user, using the user_status enum.';



-- USER ROLES
create table public.user_roles (
  id        uuid DEFAULT uuid_generate_v4() not null primary key,
  user_id   uuid references public.users on delete cascade not null,
  role      app_role not null,
  unique (user_id, role)
);
comment on table public.user_roles is 'Application roles for each user.';

-- ROLE PERMISSIONS
create table public.role_permissions (
  id           uuid DEFAULT uuid_generate_v4() not null primary key,
  role         app_role not null,
  permission   app_permission not null,
  unique (role, permission)
);
comment on table public.role_permissions is 'Application permissions for each role.';