-- Ticket Platform - Complete Database Schema Setup for Supabase
-- Run this entire script in Supabase SQL Editor to set up all tables
-- OR run individual migration files (001 → 009) for better control

-- ============================================================================
-- 1. PROFILES TABLE (extends auth.users)
-- ============================================================================
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

alter table public.profiles enable row level security;

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

create index profiles_id_idx on public.profiles(id);
create index profiles_role_idx on public.profiles(role);

-- ============================================================================
-- 2. ROUTES TABLE
-- ============================================================================
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

alter table public.routes enable row level security;

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

create index routes_transport_type_idx on public.routes(transport_type);
create index routes_departure_idx on public.routes(departure);
create index routes_destination_idx on public.routes(destination);

-- ============================================================================
-- 3. VEHICLES TABLE
-- ============================================================================
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

alter table public.vehicles enable row level security;

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

create index vehicles_route_id_idx on public.vehicles(route_id);
create index vehicles_vehicle_code_idx on public.vehicles(vehicle_code);
create index vehicles_vehicle_type_idx on public.vehicles(vehicle_type);

-- ============================================================================
-- 4. SEATS TABLE
-- ============================================================================
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

alter table public.seats enable row level security;

create policy "Seats are viewable by everyone"
  on public.seats for select
  using (true);

create policy "Users can update seat status"
  on public.seats for update
  using (true)
  with check (
    status in ('available', 'selected', 'reserved', 'occupied')
  );

create index seats_vehicle_id_idx on public.seats(vehicle_id);
create index seats_seat_code_idx on public.seats(seat_code);
create index seats_status_idx on public.seats(status);

-- ============================================================================
-- 5. BOOKINGS TABLE
-- ============================================================================
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

alter table public.bookings enable row level security;

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

create index bookings_user_id_idx on public.bookings(user_id);
create index bookings_route_id_idx on public.bookings(route_id);
create index bookings_status_idx on public.bookings(status);
create index bookings_created_at_idx on public.bookings(created_at);

-- ============================================================================
-- 6. TICKETS TABLE
-- ============================================================================
create table public.tickets (
  id uuid default gen_random_uuid() primary key,
  booking_id uuid not null references public.bookings on delete cascade,
  qr_payload text,
  boarding_status text default 'not_boarded',
  issued_at timestamp with time zone default timezone('utc'::text, now()) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.tickets enable row level security;

create policy "Users can view their own tickets"
  on public.tickets for select
  using (
    exists (
      select 1 from public.bookings
      where bookings.id = tickets.booking_id
      and bookings.user_id = auth.uid()
    )
  );

create policy "Admins can view all tickets"
  on public.tickets for select
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

create policy "Users can update their own tickets"
  on public.tickets for update
  using (
    exists (
      select 1 from public.bookings
      where bookings.id = tickets.booking_id
      and bookings.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.bookings
      where bookings.id = tickets.booking_id
      and bookings.user_id = auth.uid()
    )
  );

create index tickets_booking_id_idx on public.tickets(booking_id);
create index tickets_boarding_status_idx on public.tickets(boarding_status);

-- ============================================================================
-- 7. CHECKINS TABLE
-- ============================================================================
create table public.checkins (
  id uuid default gen_random_uuid() primary key,
  ticket_id uuid not null references public.tickets on delete cascade,
  checked_in_at timestamp with time zone default timezone('utc'::text, now()) not null,
  gate text,
  agent_id uuid references public.profiles on delete set null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.checkins enable row level security;

create policy "Users can view their own checkins"
  on public.checkins for select
  using (
    exists (
      select 1 from public.tickets
      join public.bookings on bookings.id = tickets.booking_id
      where tickets.id = checkins.ticket_id
      and bookings.user_id = auth.uid()
    )
  );

create policy "Admins can view all checkins"
  on public.checkins for select
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

create policy "Admins can insert checkins"
  on public.checkins for insert
  with check (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

create index checkins_ticket_id_idx on public.checkins(ticket_id);
create index checkins_agent_id_idx on public.checkins(agent_id);
create index checkins_checked_in_at_idx on public.checkins(checked_in_at);

-- ============================================================================
-- 8. NOTIFICATIONS TABLE
-- ============================================================================
create table public.notifications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references public.profiles on delete cascade,
  title text not null,
  message text not null,
  channel text default 'in-app',
  read_at timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.notifications enable row level security;

create policy "Users can view their own notifications"
  on public.notifications for select
  using (auth.uid() = user_id);

create policy "Users can update their own notifications"
  on public.notifications for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "System can insert notifications"
  on public.notifications for insert
  with check (true);

create index notifications_user_id_idx on public.notifications(user_id);
create index notifications_read_at_idx on public.notifications(read_at);
create index notifications_created_at_idx on public.notifications(created_at);

-- ============================================================================
-- 9. SEED DATA (Optional - for testing/development)
-- ============================================================================
-- Insert sample routes
insert into public.routes (transport_type, departure, destination, departure_time, arrival_time)
values
  ('Train', 'Hanoi', 'Da Nang', '08:15', '14:20'),
  ('Flight', 'Ho Chi Minh City', 'Singapore', '09:45', '12:35'),
  ('Train', 'Hue', 'Nha Trang', '21:25', '05:40'),
  ('Bus', 'Hanoi', 'Hai Phong', '06:30', '09:00'),
  ('Flight', 'Hanoi', 'Ho Chi Minh City', '14:00', '15:45')
on conflict do nothing;

-- Insert sample vehicles
insert into public.vehicles (route_id, vehicle_code, vehicle_type, capacity, deck_layout)
select 
  r.id,
  'VEH-' || substr(md5(random()::text), 1, 6),
  case 
    when r.transport_type = 'Train' then 'Coach'
    when r.transport_type = 'Flight' then 'Aircraft'
    else 'Bus'
  end,
  case 
    when r.transport_type = 'Train' then 120
    when r.transport_type = 'Flight' then 180
    else 50
  end,
  jsonb_build_object('rows', 12, 'columns', 4)
from public.routes r
where not exists (select 1 from public.vehicles where route_id = r.id)
on conflict do nothing;

-- Insert sample seats (first 100 only)
insert into public.seats (vehicle_id, seat_code, seat_class, status, position_meta)
with seat_generation as (
  select 
    v.id,
    chr(65 + (row_number() over (partition by v.id order by s.num))::int / 12) || 
    (((row_number() over (partition by v.id order by s.num))::int - 1) % 12 + 1)::text as seat_code,
    case 
      when (row_number() over (partition by v.id order by s.num))::int % 4 in (1, 4) then 'window'
      else 'aisle'
    end as seat_class,
    case 
      when random() < 0.05 then 'occupied'
      when random() < 0.10 then 'reserved'
      else 'available'
    end as status,
    jsonb_build_object(
      'x', (((row_number() over (partition by v.id order by s.num))::int - 1) % 4 * 80 + 40)::int,
      'y', ((((row_number() over (partition by v.id order by s.num))::int - 1) / 4) * 80 + 40)::int
    ) as position_meta
  from public.vehicles v,
       lateral generate_series(1, 48) as s(num)
  limit 100
)
select * from seat_generation
on conflict do nothing;

-- ============================================================================
-- SETUP NOTES
-- ============================================================================
-- 1. After running this script, create your first admin user
-- 2. Go to Supabase Dashboard > SQL Editor > New Query
-- 3. Run: UPDATE public.profiles SET role = 'admin' WHERE email = 'your-admin-email@example.com';
-- 4. Configure Google OAuth in your Supabase project
-- 5. Update .env file with VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY
