create table public.profiles (
  id uuid not null,
  updated_at timestamp with time zone null,
  display_name text null,
  full_name text null,
  avatar_url text null,
  website text null,
  username text null,
  constraint profiles_pkey primary key (id),
  constraint profiles_username_key unique (display_name),
  constraint profiles_id_fkey foreign KEY (id) references auth.users (id),
  constraint username_length check ((char_length(display_name) >= 3))
) TABLESPACE pg_default;

--we have a menu-crimes-photos bucket in supabase
--Anyone can delete from menu-crimes-photos

--UPDATE
--Anyone can update menu-crimes-photos

--INSERT
--Anyone can upload to menu-crimes-photos

--SELECT
--Anyone can view menu-crimes-photos

