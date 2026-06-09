-- Create profiles table (extends auth.users)
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  email text not null,
  first_name text,
  last_name text,
  avatar_url text,
  role text default 'user' not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.profiles enable row level security;

-- Create policies
create policy "Public profiles are viewable by everyone"
  on public.profiles for select
  using (true);

create policy "Users can insert their own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Create index
create index profiles_id_idx on public.profiles(id);
create index profiles_role_idx on public.profiles(role);
