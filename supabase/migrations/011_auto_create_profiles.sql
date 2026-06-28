create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    email,
    first_name,
    last_name,
    avatar_url
  )
  values (
    new.id,
    coalesce(new.email, ''),
    new.raw_user_meta_data ->> 'given_name',
    coalesce(new.raw_user_meta_data ->> 'family_name', new.raw_user_meta_data ->> 'last_name'),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do update
  set
    email = excluded.email,
    first_name = coalesce(public.profiles.first_name, excluded.first_name),
    last_name = coalesce(public.profiles.last_name, excluded.last_name),
    avatar_url = coalesce(public.profiles.avatar_url, excluded.avatar_url),
    updated_at = timezone('utc'::text, now());

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

insert into public.profiles (
  id,
  email,
  first_name,
  last_name,
  avatar_url
)
select
  auth_users.id,
  coalesce(auth_users.email, ''),
  auth_users.raw_user_meta_data ->> 'given_name',
  coalesce(auth_users.raw_user_meta_data ->> 'family_name', auth_users.raw_user_meta_data ->> 'last_name'),
  auth_users.raw_user_meta_data ->> 'avatar_url'
from auth.users as auth_users
left join public.profiles on public.profiles.id = auth_users.id
where public.profiles.id is null;
