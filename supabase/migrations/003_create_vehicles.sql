-- Create vehicles table
create table public.vehicles (
  id uuid default gen_random_uuid() primary key,
  route_id uuid not null references public.routes on delete cascade,
  vehicle_code text not null unique,
  vehicle_type text not null,
  capacity integer not null,
  deck_layout jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.vehicles enable row level security;

-- Create policies
create policy "Vehicles are viewable by everyone"
  on public.vehicles for select
  using (true);

create policy "Only admins can insert vehicles"
  on public.vehicles for insert
  with check (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

create policy "Only admins can update vehicles"
  on public.vehicles for update
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
create index vehicles_route_id_idx on public.vehicles(route_id);
create index vehicles_vehicle_code_idx on public.vehicles(vehicle_code);
create index vehicles_vehicle_type_idx on public.vehicles(vehicle_type);
