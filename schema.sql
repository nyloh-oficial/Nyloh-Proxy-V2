-- Run this entire file in Supabase SQL Editor.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  role text not null default 'user' check (role in ('user','admin')),
  is_banned boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists public.messages (
  id bigint generated always as identity primary key,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 1500),
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
alter table public.messages enable row level security;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
declare desired_username text;
begin
  desired_username := lower(coalesce(new.raw_user_meta_data->>'username', split_part(new.email,'@',1)));
  insert into public.profiles(id,username) values(new.id,desired_username);
  return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public
as $$ select exists(select 1 from public.profiles where id=auth.uid() and role='admin' and is_banned=false); $$;

-- Users can see their own profile. Admins can see profiles for moderation and username lookup.
drop policy if exists "read own or admin profiles" on public.profiles;
create policy "read own or admin profiles" on public.profiles for select to authenticated
using (id=auth.uid() or public.is_admin());

-- These SECURITY DEFINER helpers expose only the username/id needed by the app,
-- without granting regular users broad read access to profile records.
create or replace function public.lookup_active_user(target_username text)
returns uuid language sql stable security definer set search_path = public
as $$
  select id from public.profiles
  where username=lower(target_username) and is_banned=false
  limit 1;
$$;
grant execute on function public.lookup_active_user(text) to authenticated;

create or replace function public.get_usernames_for_ids(user_ids uuid[])
returns table(id uuid, username text)
language sql stable security definer set search_path = public
as $$
  select p.id,p.username from public.profiles p
  where p.id = any(user_ids)
    and (p.id=auth.uid() or exists (
      select 1 from public.messages m
      where (m.sender_id=auth.uid() and m.recipient_id=p.id)
         or (m.recipient_id=auth.uid() and m.sender_id=p.id)
    ));
$$;
grant execute on function public.get_usernames_for_ids(uuid[]) to authenticated;
drop policy if exists "read participating messages" on public.messages;
create policy "read participating messages" on public.messages for select to authenticated
using (sender_id=auth.uid() or recipient_id=auth.uid());
drop policy if exists "send as self" on public.messages;
create policy "send as self" on public.messages for insert to authenticated
with check (sender_id=auth.uid() and exists(select 1 from public.profiles p where p.id=recipient_id and p.is_banned=false));

create or replace function public.admin_toggle_ban(target_username text)
returns json language plpgsql security definer set search_path = public
as $$
declare target public.profiles;
begin
  if not public.is_admin() then raise exception 'Owner access required'; end if;
  select * into target from public.profiles where username=lower(target_username);
  if target.id is null then raise exception 'Username not found'; end if;
  if target.role='admin' then raise exception 'Owner account cannot be banned'; end if;
  update public.profiles set is_banned=not target.is_banned where id=target.id;
  return json_build_object('message',case when not target.is_banned then 'User banned.' else 'User unbanned.' end);
end; $$;
grant execute on function public.admin_toggle_ban(text) to authenticated;

-- Allow Supabase Realtime to publish new messages (safe to re-run).
do $$ begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end $$;

-- After creating the owner account once through the website, run this:
-- update public.profiles set role='admin' where username='nyloh51';
