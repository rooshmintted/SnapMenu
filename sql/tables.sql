create table public.friend_requests (
  id uuid not null default gen_random_uuid (),
  sender_id uuid not null,
  receiver_id uuid not null,
  status text not null default 'pending'::text,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint friend_requests_pkey primary key (id),
  constraint friend_requests_unique_pair unique (sender_id, receiver_id),
  constraint friend_requests_receiver_id_fkey foreign KEY (receiver_id) references profiles (id) on delete CASCADE,
  constraint friend_requests_sender_id_fkey foreign KEY (sender_id) references profiles (id) on delete CASCADE,
  constraint friend_requests_no_self_request check ((sender_id <> receiver_id)),
  constraint friend_requests_status_check check (
    (
      status = any (
        array[
          'pending'::text,
          'accepted'::text,
          'rejected'::text,
          'blocked'::text
        ]
      )
    )
  )
) TABLESPACE pg_default;

create index IF not exists friend_requests_sender_id_idx on public.friend_requests using btree (sender_id) TABLESPACE pg_default;

create index IF not exists friend_requests_receiver_id_idx on public.friend_requests using btree (receiver_id) TABLESPACE pg_default;

create index IF not exists friend_requests_status_idx on public.friend_requests using btree (status) TABLESPACE pg_default;

create trigger on_friend_request_accepted
after
update on friend_requests for EACH row
execute FUNCTION handle_friend_request_acceptance ();

create trigger on_friend_request_rejected
after
update on friend_requests for EACH row
execute FUNCTION handle_friend_request_rejection ();

create table public.friendships (
  id uuid not null default gen_random_uuid (),
  user_id1 uuid not null,
  user_id2 uuid not null,
  created_at timestamp with time zone null default now(),
  constraint friendships_pkey primary key (id),
  constraint friendships_unique_pair unique (user_id1, user_id2),
  constraint friendships_user_id1_fkey foreign KEY (user_id1) references profiles (id) on delete CASCADE,
  constraint friendships_user_id2_fkey foreign KEY (user_id2) references profiles (id) on delete CASCADE,
  constraint friendships_no_self_friendship check ((user_id1 <> user_id2))
) TABLESPACE pg_default;

create index IF not exists friendships_user_id1_idx on public.friendships using btree (user_id1) TABLESPACE pg_default;

create index IF not exists friendships_user_id2_idx on public.friendships using btree (user_id2) TABLESPACE pg_default;

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

create table public.shared_photos (
  id uuid not null default gen_random_uuid (),
  sender_id uuid not null,
  receiver_id uuid not null,
  media_url text not null,
  caption text null,
  is_viewed boolean not null default false,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  media_type text not null default 'photo'::text,
  duration_seconds integer null,
  constraint shared_photos_pkey primary key (id),
  constraint shared_photos_receiver_id_fkey foreign KEY (receiver_id) references profiles (id) on delete CASCADE,
  constraint shared_photos_sender_id_fkey foreign KEY (sender_id) references profiles (id) on delete CASCADE,
  constraint no_self_share check ((sender_id <> receiver_id)),
  constraint shared_photos_media_type_check check (
    (
      media_type = any (array['photo'::text, 'video'::text])
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_shared_photos_receiver_created on public.shared_photos using btree (receiver_id, created_at desc) TABLESPACE pg_default;

create index IF not exists idx_shared_photos_sender_created on public.shared_photos using btree (sender_id, created_at desc) TABLESPACE pg_default;

create index IF not exists idx_shared_photos_unviewed on public.shared_photos using btree (receiver_id, is_viewed) TABLESPACE pg_default
where
  (is_viewed = false);

create index IF not exists idx_shared_photos_media_type on public.shared_photos using btree (media_type) TABLESPACE pg_default;

create trigger trigger_shared_photos_updated_at BEFORE
update on shared_photos for EACH row
execute FUNCTION update_shared_photos_updated_at ();

create view public.shared_photos_with_profiles as
select
  sp.id,
  sp.sender_id,
  sp.receiver_id,
  sp.media_url as image_url,
  sp.caption,
  sp.is_viewed,
  sp.created_at,
  sp.updated_at,
  sender.username as sender_username,
  sender.full_name as sender_full_name,
  sender.avatar_url as sender_avatar_url,
  receiver.username as receiver_username,
  receiver.full_name as receiver_full_name,
  receiver.avatar_url as receiver_avatar_url
from
  shared_photos sp
  left join profiles sender on sp.sender_id = sender.id
  left join profiles receiver on sp.receiver_id = receiver.id;

  create table public.stories (
  id uuid not null default gen_random_uuid (),
  user_id uuid not null,
  media_url text not null,
  media_type text not null default 'photo'::text,
  duration_seconds integer null,
  caption text null,
  created_at timestamp with time zone not null default now(),
  expires_at timestamp with time zone not null default (now() + '24:00:00'::interval),
  constraint stories_pkey primary key (id),
  constraint stories_user_id_fkey foreign KEY (user_id) references profiles (id) on delete CASCADE,
  constraint stories_media_type_check check (
    (
      media_type = any (array['photo'::text, 'video'::text])
    )
  ),
  constraint valid_user check ((user_id is not null))
) TABLESPACE pg_default;

create index IF not exists idx_stories_user_time on public.stories using btree (user_id, expires_at desc, created_at desc) TABLESPACE pg_default;

create index IF not exists idx_stories_expires_at on public.stories using btree (expires_at, created_at desc) TABLESPACE pg_default;

create index IF not exists idx_stories_media_type on public.stories using btree (media_type) TABLESPACE pg_default;

create index IF not exists idx_stories_cleanup on public.stories using btree (expires_at) TABLESPACE pg_default;

CREATE TABLE public.menu_analyses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id uuid REFERENCES public.stories(id) ON DELETE CASCADE,
  image_url text NOT NULL,
  analysis_data jsonb NOT NULL,
  dishes_count integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.dish_analyses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id uuid REFERENCES public.stories(id) ON DELETE CASCADE,
  dish_name text NOT NULL,
  margin_percentage integer NOT NULL,
  justification text NOT NULL,
  coordinates jsonb NOT NULL,
  price text,
  estimated_food_cost decimal(10,2),
  created_at timestamp with time zone DEFAULT now()
);
