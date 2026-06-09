-- Create seats table
create table public.seats (
  id uuid default gen_random_uuid() primary key,
  vehicle_id uuid not null references public.vehicles on delete cascade,
  seat_code text not null,
  seat_class text not null,
  status text not null default 'available',
  position_meta jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(vehicle_id, seat_code)
);

-- Enable RLS
alter table public.seats enable row level security;

-- Create policies
create policy "Seats are viewable by everyone"
  on public.seats for select
  using (true);

create policy "Users can update seat status"
  on public.seats for update
  using (true)
  with check (
    status in ('available', 'selected', 'reserved', 'occupied')
  );

-- Create indexes
create index seats_vehicle_id_idx on public.seats(vehicle_id);
create index seats_seat_code_idx on public.seats(seat_code);
create index seats_status_idx on public.seats(status);
