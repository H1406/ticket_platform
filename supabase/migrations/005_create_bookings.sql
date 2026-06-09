-- Create bookings table
create table public.bookings (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references public.profiles on delete cascade,
  route_id uuid not null references public.routes on delete cascade,
  seat_ids uuid[] default array[]::uuid[],
  status text not null default 'pending',
  hold_expires_at timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.bookings enable row level security;

-- Create policies
create policy "Users can view their own bookings"
  on public.bookings for select
  using (auth.uid() = user_id);

create policy "Admins can view all bookings"
  on public.bookings for select
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

create policy "Users can insert their own bookings"
  on public.bookings for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own bookings"
  on public.bookings for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Create indexes
create index bookings_user_id_idx on public.bookings(user_id);
create index bookings_route_id_idx on public.bookings(route_id);
create index bookings_status_idx on public.bookings(status);
create index bookings_created_at_idx on public.bookings(created_at);
