-- Create routes table
create table public.routes (
  id uuid default gen_random_uuid() primary key,
  transport_type text not null,
  departure text not null,
  destination text not null,
  departure_time time not null,
  arrival_time time not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.routes enable row level security;

-- Create policies
create policy "Routes are viewable by everyone"
  on public.routes for select
  using (true);

create policy "Only admins can insert routes"
  on public.routes for insert
  with check (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

create policy "Only admins can update routes"
  on public.routes for update
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  )
  with check (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

-- Create indexes
create index routes_transport_type_idx on public.routes(transport_type);
create index routes_departure_idx on public.routes(departure);
create index routes_destination_idx on public.routes(destination);
