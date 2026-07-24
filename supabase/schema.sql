-- Ticket Platform - Clean Supabase bootstrap schema
-- Run this on a fresh Supabase project to create the full schema from scratch.
-- This file is intentionally organized as one coherent setup, without later
-- patch fragments or duplicate seed blocks.

create extension if not exists pgcrypto;

-- ============================================================================
-- 1. UTILITY FUNCTION
-- ============================================================================
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc'::text, now());
  return new;
end;
$$;

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

-- ============================================================================
-- 2. PROFILES TABLE (extends auth.users)
-- ============================================================================
create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  email text not null,
  first_name text,
  last_name text,
  avatar_url text,
  role text not null default 'user',
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  updated_at timestamp with time zone not null default timezone('utc'::text, now())
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

create trigger set_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

-- ============================================================================
-- 3. ROUTES TABLE
-- ============================================================================
create table public.routes (
  id uuid primary key default gen_random_uuid(),
  transport_type text not null,
  departure text not null,
  destination text not null,
  departure_time time not null,
  arrival_time time not null,
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  updated_at timestamp with time zone not null default timezone('utc'::text, now())
);

alter table public.routes enable row level security;

create policy "Routes are viewable by everyone"
  on public.routes for select
  using (true);

create policy "Only admins can insert routes"
  on public.routes for insert
  with check (
    exists (
      select 1
      from public.profiles
      where id = auth.uid()
        and role = 'admin'
    )
  );

create policy "Only admins can update routes"
  on public.routes for update
  using (
    exists (
      select 1
      from public.profiles
      where id = auth.uid()
        and role = 'admin'
    )
  )
  with check (
    exists (
      select 1
      from public.profiles
      where id = auth.uid()
        and role = 'admin'
    )
  );

create index routes_transport_type_idx on public.routes(transport_type);
create index routes_departure_idx on public.routes(departure);
create index routes_destination_idx on public.routes(destination);

create trigger set_routes_updated_at
before update on public.routes
for each row
execute function public.set_updated_at();

-- ============================================================================
-- 4. VEHICLES TABLE
-- ============================================================================
create table public.vehicles (
  id uuid primary key default gen_random_uuid(),
  route_id uuid not null references public.routes on delete cascade,
  vehicle_code text not null unique,
  vehicle_type text not null,
  capacity integer not null check (capacity > 0),
  deck_layout jsonb,
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  updated_at timestamp with time zone not null default timezone('utc'::text, now())
);

alter table public.vehicles enable row level security;

create policy "Vehicles are viewable by everyone"
  on public.vehicles for select
  using (true);

create policy "Only admins can insert vehicles"
  on public.vehicles for insert
  with check (
    exists (
      select 1
      from public.profiles
      where id = auth.uid()
        and role = 'admin'
    )
  );

create policy "Only admins can update vehicles"
  on public.vehicles for update
  using (
    exists (
      select 1
      from public.profiles
      where id = auth.uid()
        and role = 'admin'
    )
  )
  with check (
    exists (
      select 1
      from public.profiles
      where id = auth.uid()
        and role = 'admin'
    )
  );

create index vehicles_route_id_idx on public.vehicles(route_id);
create index vehicles_vehicle_code_idx on public.vehicles(vehicle_code);
create index vehicles_vehicle_type_idx on public.vehicles(vehicle_type);

create trigger set_vehicles_updated_at
before update on public.vehicles
for each row
execute function public.set_updated_at();

-- ============================================================================
-- 5. BOOKINGS TABLE
-- ============================================================================
create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles on delete cascade,
  route_id uuid not null references public.routes on delete cascade,
  seat_ids uuid[] not null default array[]::uuid[],
  travel_date date not null default timezone('utc'::text, now())::date,
  status text not null default 'draft'
    check (status in ('draft', 'held', 'confirmed', 'cancelled', 'expired')),
  hold_expires_at timestamp with time zone,
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  updated_at timestamp with time zone not null default timezone('utc'::text, now())
);

alter table public.bookings enable row level security;

create policy "Users can view their own bookings"
  on public.bookings for select
  using (auth.uid() = user_id);

create policy "Admins can view all bookings"
  on public.bookings for select
  using (
    exists (
      select 1
      from public.profiles
      where id = auth.uid()
        and role = 'admin'
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
create index bookings_hold_expires_at_idx on public.bookings(hold_expires_at);
create index bookings_travel_date_idx on public.bookings(travel_date);
create index bookings_route_travel_date_idx on public.bookings(route_id, travel_date);

create trigger set_bookings_updated_at
before update on public.bookings
for each row
execute function public.set_updated_at();

-- ============================================================================
-- 6. SEATS TABLE
-- Created after bookings so held_by_booking_id can reference bookings cleanly.
-- ============================================================================
create table public.seats (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references public.vehicles on delete cascade,
  seat_code text not null,
  seat_class text not null,
  status text not null default 'available'
    check (status in ('available', 'held', 'booked')),
  held_by_booking_id uuid references public.bookings on delete set null,
  held_by_user_id uuid references public.profiles on delete set null,
  hold_expires_at timestamp with time zone,
  position_meta jsonb,
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  updated_at timestamp with time zone not null default timezone('utc'::text, now()),
  unique (vehicle_id, seat_code)
);

alter table public.seats enable row level security;

create policy "Seats are viewable by everyone"
  on public.seats for select
  using (true);

create policy "Users can update seat status"
  on public.seats for update
  using (auth.role() = 'authenticated')
  with check (
    auth.role() = 'authenticated'
    and status in ('available', 'held', 'booked')
  );

create index seats_vehicle_id_idx on public.seats(vehicle_id);
create index seats_seat_code_idx on public.seats(seat_code);
create index seats_status_idx on public.seats(status);
create index seats_held_by_booking_id_idx on public.seats(held_by_booking_id);
create index seats_held_by_user_id_idx on public.seats(held_by_user_id);
create index seats_hold_expires_at_idx on public.seats(hold_expires_at);

create trigger set_seats_updated_at
before update on public.seats
for each row
execute function public.set_updated_at();

do $$
begin
  alter publication supabase_realtime add table public.seats;
exception
  when duplicate_object then null;
end;
$$;

-- ============================================================================
-- 7. TICKETS TABLE
-- ============================================================================
create table public.tickets (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings on delete cascade,
  qr_payload text,
  boarding_status text not null default 'not_boarded',
  issued_at timestamp with time zone not null default timezone('utc'::text, now()),
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  updated_at timestamp with time zone not null default timezone('utc'::text, now())
);

alter table public.tickets enable row level security;

create policy "Users can view their own tickets"
  on public.tickets for select
  using (
    exists (
      select 1
      from public.bookings
      where bookings.id = tickets.booking_id
        and bookings.user_id = auth.uid()
    )
  );

create policy "Admins can view all tickets"
  on public.tickets for select
  using (
    exists (
      select 1
      from public.profiles
      where id = auth.uid()
        and role = 'admin'
    )
  );

create policy "Users can update their own tickets"
  on public.tickets for update
  using (
    exists (
      select 1
      from public.bookings
      where bookings.id = tickets.booking_id
        and bookings.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.bookings
      where bookings.id = tickets.booking_id
        and bookings.user_id = auth.uid()
    )
  );

create index tickets_booking_id_idx on public.tickets(booking_id);
create index tickets_boarding_status_idx on public.tickets(boarding_status);

create trigger set_tickets_updated_at
before update on public.tickets
for each row
execute function public.set_updated_at();

-- ============================================================================
-- 8. CHECKINS TABLE
-- ============================================================================
create table public.checkins (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.tickets on delete cascade,
  checked_in_at timestamp with time zone not null default timezone('utc'::text, now()),
  gate text,
  agent_id uuid references public.profiles on delete set null,
  created_at timestamp with time zone not null default timezone('utc'::text, now())
);

alter table public.checkins enable row level security;

create policy "Users can view their own checkins"
  on public.checkins for select
  using (
    exists (
      select 1
      from public.tickets
      join public.bookings on bookings.id = tickets.booking_id
      where tickets.id = checkins.ticket_id
        and bookings.user_id = auth.uid()
    )
  );

create policy "Admins can view all checkins"
  on public.checkins for select
  using (
    exists (
      select 1
      from public.profiles
      where id = auth.uid()
        and role = 'admin'
    )
  );

create policy "Admins can insert checkins"
  on public.checkins for insert
  with check (
    exists (
      select 1
      from public.profiles
      where id = auth.uid()
        and role = 'admin'
    )
  );

create index checkins_ticket_id_idx on public.checkins(ticket_id);
create index checkins_agent_id_idx on public.checkins(agent_id);
create index checkins_checked_in_at_idx on public.checkins(checked_in_at);

-- ============================================================================
-- 9. NOTIFICATIONS TABLE
-- ============================================================================
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles on delete cascade,
  title text not null,
  message text not null,
  channel text default 'in-app',
  read_at timestamp with time zone,
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  updated_at timestamp with time zone not null default timezone('utc'::text, now())
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

create trigger set_notifications_updated_at
before update on public.notifications
for each row
execute function public.set_updated_at();

-- ============================================================================
-- 10. REALTIME BOOKING FUNCTIONS
-- ============================================================================
create or replace function public.release_expired_seat_holds()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  released_count integer := 0;
begin
  update public.seats
  set
    status             = 'available',
    held_by_booking_id = null,
    held_by_user_id    = null,
    hold_expires_at    = null
  where seats.status          = 'held'
    and seats.hold_expires_at is not null
    and seats.hold_expires_at <= timezone('utc'::text, now());

  get diagnostics released_count = row_count;

  update public.bookings
  set
    status = case
      when exists (
        select 1
        from public.seats s
        where s.held_by_booking_id = bookings.id
          and s.status = 'booked'
      ) then 'confirmed'
      else 'expired'
    end,
    seat_ids = coalesce((
      select array_agg(s.id order by s.seat_code)
      from public.seats s
      where s.held_by_booking_id = bookings.id
        and s.status <> 'available'
    ), array[]::uuid[]),
    hold_expires_at = null
  where bookings.status = 'held'
    and bookings.hold_expires_at is not null
    and bookings.hold_expires_at <= timezone('utc'::text, now());

  update public.bookings
  set
    status          = 'draft',
    seat_ids        = array[]::uuid[],
    hold_expires_at = null
  where bookings.status = 'expired'
    and coalesce(array_length(bookings.seat_ids, 1), 0) = 0;

  return released_count;
end;
$$;

create or replace function public.hold_seat(
  p_route_id uuid,
  p_seat_id uuid,
  p_booking_id uuid default null,
  p_hold_minutes integer default 5,
  p_travel_date date default timezone('utc'::text, now())::date
)
returns table (
  booking_id uuid,
  seat_id uuid,
  status text,
  hold_expires_at timestamp with time zone
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking_id uuid;
  v_user_id uuid := auth.uid();
  v_seat public.seats%rowtype;
  v_travel_date date := coalesce(p_travel_date, timezone('utc'::text, now())::date);
  v_hold_expires_at timestamp with time zone :=
    timezone('utc'::text, now()) + make_interval(mins => greatest(1, least(p_hold_minutes, 10)));
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  perform public.release_expired_seat_holds();

  select s.*
  into v_seat
  from public.seats s
  join public.vehicles v on v.id = s.vehicle_id
  where s.id = p_seat_id
    and v.route_id = p_route_id
  for update;

  if not found then
    raise exception 'Seat not found for route';
  end if;

  if exists (
    select 1
    from public.bookings b
    where b.route_id = p_route_id
      and b.travel_date = v_travel_date
      and b.status = 'confirmed'
      and p_seat_id = any(b.seat_ids)
  ) then
    raise exception 'Seat is already booked';
  end if;

  if v_seat.status = 'held'
     and v_seat.hold_expires_at is not null
     and v_seat.hold_expires_at > timezone('utc'::text, now())
     and v_seat.held_by_user_id is distinct from v_user_id then
    raise exception 'Seat is currently held by another passenger';
  end if;

  if p_booking_id is not null then
    select bookings.id
    into v_booking_id
    from public.bookings
    where bookings.id = p_booking_id
      and bookings.user_id = v_user_id
      and bookings.route_id = p_route_id
    for update;
  end if;

  if v_booking_id is null then
    insert into public.bookings (user_id, route_id, travel_date, seat_ids, status, hold_expires_at)
    values (v_user_id, p_route_id, v_travel_date, array[p_seat_id], 'held', v_hold_expires_at)
    returning bookings.id into v_booking_id;
  end if;

  update public.seats
  set
    status = 'held',
    held_by_booking_id = v_booking_id,
    held_by_user_id = v_user_id,
    hold_expires_at = v_hold_expires_at
  where seats.id = p_seat_id;

  update public.bookings
  set
    status = 'held',
    travel_date = v_travel_date,
    seat_ids = coalesce((
      select array_agg(s.id order by s.seat_code)
      from public.seats s
      where s.held_by_booking_id = v_booking_id
        and s.status = 'held'
        and s.hold_expires_at > timezone('utc'::text, now())
    ), array[]::uuid[]),
    hold_expires_at = v_hold_expires_at
  where bookings.id = v_booking_id;

  return query
  select v_booking_id, p_seat_id, 'held'::text, v_hold_expires_at;
end;
$$;

create or replace function public.release_seat_hold(
  p_seat_id uuid,
  p_booking_id uuid default null
)
returns table (
  booking_id uuid,
  released_seat_id uuid
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_booking_id uuid;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  perform public.release_expired_seat_holds();

  select seats.held_by_booking_id
  into v_booking_id
  from public.seats
  where seats.id = p_seat_id
    and seats.held_by_user_id = v_user_id
    and seats.status = 'held'
  for update;

  if p_booking_id is not null and v_booking_id is distinct from p_booking_id then
    raise exception 'Seat is not held by the provided booking';
  end if;

  update public.seats
  set
    status = 'available',
    held_by_booking_id = null,
    held_by_user_id = null,
    hold_expires_at = null
  where seats.id = p_seat_id
    and seats.held_by_user_id = v_user_id
    and seats.status = 'held';

  if v_booking_id is not null then
    update public.bookings
    set
      seat_ids = coalesce((
        select array_agg(s.id order by s.seat_code)
        from public.seats s
        where s.held_by_booking_id = v_booking_id
          and s.status = 'held'
          and s.hold_expires_at > timezone('utc'::text, now())
      ), array[]::uuid[]),
      hold_expires_at = (
        select max(s.hold_expires_at)
        from public.seats s
        where s.held_by_booking_id = v_booking_id
          and s.status = 'held'
      ),
      status = case
        when exists (
          select 1
          from public.seats s
          where s.held_by_booking_id = v_booking_id
            and s.status = 'held'
        ) then 'held'
        else 'draft'
      end
    where bookings.id = v_booking_id
      and bookings.user_id = v_user_id;
  end if;

  return query
  select v_booking_id, p_seat_id;
end;
$$;

create or replace function public.release_booking_holds(
  p_booking_id uuid,
  p_cancel boolean default true
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  released_count integer := 0;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  update public.seats
  set
    status = 'available',
    held_by_booking_id = null,
    held_by_user_id = null,
    hold_expires_at = null
  where seats.held_by_booking_id = p_booking_id
    and seats.held_by_user_id = v_user_id
    and seats.status = 'held';

  get diagnostics released_count = row_count;

  update public.bookings
  set
    seat_ids = array[]::uuid[],
    hold_expires_at = null,
    status = case when p_cancel then 'cancelled' else 'draft' end
  where bookings.id = p_booking_id
    and bookings.user_id = v_user_id
    and bookings.status <> 'confirmed';

  return released_count;
end;
$$;

create or replace function public.confirm_booking(
  p_booking_id uuid,
  p_travel_date date default null
)
returns table (
  booking_id uuid,
  ticket_id uuid,
  qr_payload text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_ticket_id uuid;
  v_now timestamp with time zone := timezone('utc'::text, now());
  v_route_id uuid;
  v_travel_date date;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  perform public.release_expired_seat_holds();

  select bookings.route_id, coalesce(p_travel_date, bookings.travel_date, bookings.created_at::date)
  into v_route_id, v_travel_date
  from public.bookings
  where bookings.id = p_booking_id
    and bookings.user_id = v_user_id
    and bookings.status in ('held', 'draft')
  for update;

  if v_route_id is null then
    raise exception 'Booking was not found';
  end if;

  perform 1
  from public.seats
  where seats.held_by_booking_id = p_booking_id
    and seats.held_by_user_id = v_user_id
    and seats.status = 'held'
    and seats.hold_expires_at > v_now
  for update;

  if not found then
    raise exception 'There are no active seat holds to confirm';
  end if;

  if exists (
    select 1
    from public.seats
    where seats.held_by_booking_id = p_booking_id
      and (
        seats.status <> 'held'
        or seats.hold_expires_at is null
        or seats.hold_expires_at <= v_now
      )
  ) then
    raise exception 'One or more seats are no longer available';
  end if;

  if exists (
    select 1
    from public.bookings b
    where b.route_id = v_route_id
      and b.travel_date = v_travel_date
      and b.status = 'confirmed'
      and b.id <> p_booking_id
      and b.seat_ids && (
        select array_agg(s.id)
        from public.seats s
        where s.held_by_booking_id = p_booking_id
          and s.status = 'held'
      )
  ) then
    raise exception 'One or more seats are already booked for this travel date';
  end if;

  update public.bookings
  set
    status = 'confirmed',
    travel_date = v_travel_date,
    seat_ids = (
      select array_agg(s.id order by s.seat_code)
      from public.seats s
      where s.held_by_booking_id = p_booking_id
        and s.status = 'held'
    ),
    hold_expires_at = null
  where bookings.id = p_booking_id
    and bookings.user_id = v_user_id;

  insert into public.tickets (booking_id, qr_payload, boarding_status)
  values (p_booking_id, null, 'not_boarded')
  returning tickets.id into v_ticket_id;

  update public.tickets
  set qr_payload = v_ticket_id::text
  where tickets.id = v_ticket_id;

  update public.seats
  set
    status = 'available',
    held_by_booking_id = null,
    held_by_user_id = null,
    hold_expires_at = null
  where seats.held_by_booking_id = p_booking_id
    and seats.held_by_user_id = v_user_id
    and seats.status = 'held';

  return query
  select p_booking_id, v_ticket_id, v_ticket_id::text;
end;
$$;

grant execute on function public.release_expired_seat_holds() to authenticated, anon;
grant execute on function public.hold_seat(uuid, uuid, uuid, integer, date) to authenticated;
grant execute on function public.release_seat_hold(uuid, uuid) to authenticated;
grant execute on function public.release_booking_holds(uuid, boolean) to authenticated;
grant execute on function public.confirm_booking(uuid, date) to authenticated;

-- ============================================================================
-- 10a. ADMIN TICKET CHECK-IN
-- ============================================================================
create policy "Admins can update tickets"
  on public.tickets for update
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

create or replace function public.check_in_ticket(
  p_qr_payload text,
  p_gate text default null
)
returns table (
  result_status text,
  ticket_id uuid,
  booking_id uuid,
  boarding_status text,
  checked_in_at timestamp with time zone,
  passenger_name text,
  route_departure text,
  route_destination text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_is_admin boolean;
  v_ticket_id uuid;
  v_booking_id uuid;
  v_boarding_status text;
  v_travel_date date;
  v_booking_created_at timestamp with time zone;
  v_departure_time time;
  v_route_departure text;
  v_route_destination text;
  v_passenger_name text;
  v_departure_at timestamp with time zone;
  v_existing_checkin_at timestamp with time zone;
  v_now timestamp with time zone := timezone('utc'::text, now());
  v_checked_in_at timestamp with time zone;
begin
  select exists(
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  ) into v_is_admin;

  if not v_is_admin then
    raise exception 'Admin privileges required';
  end if;

  select
    t.id, t.booking_id, t.boarding_status,
    b.travel_date, b.created_at, r.departure_time, r.departure, r.destination,
    trim(coalesce(p.first_name, '') || ' ' || coalesce(p.last_name, ''))
  into
    v_ticket_id, v_booking_id, v_boarding_status,
    v_travel_date, v_booking_created_at, v_departure_time, v_route_departure, v_route_destination,
    v_passenger_name
  from public.tickets t
  join public.bookings b on b.id = t.booking_id
  join public.routes r on r.id = b.route_id
  left join public.profiles p on p.id = b.user_id
  where t.qr_payload = p_qr_payload or t.id::text = p_qr_payload
  limit 1;

  if v_ticket_id is null then
    return query select 'not_found', null::uuid, null::uuid, null::text, null::timestamptz, null::text, null::text, null::text;
    return;
  end if;

  if v_boarding_status = 'checked_in' then
    select c.checked_in_at into v_existing_checkin_at
    from public.checkins c
    where c.ticket_id = v_ticket_id
    order by c.checked_in_at desc
    limit 1;

    return query select
      'already_checked_in', v_ticket_id, v_booking_id, v_boarding_status,
      v_existing_checkin_at, v_passenger_name, v_route_departure, v_route_destination;
    return;
  end if;

  v_departure_at := coalesce(v_travel_date, v_booking_created_at::date)::timestamp
    + coalesce(v_departure_time, '00:00'::time);

  if v_now > v_departure_at then
    return query select
      'expired', v_ticket_id, v_booking_id, v_boarding_status,
      null::timestamptz, v_passenger_name, v_route_departure, v_route_destination;
    return;
  end if;

  insert into public.checkins as inserted_checkin (ticket_id, gate, agent_id)
  values (v_ticket_id, p_gate, auth.uid())
  returning inserted_checkin.checked_in_at into v_checked_in_at;

  update public.tickets
  set boarding_status = 'checked_in'
  where id = v_ticket_id;

  return query select
    'checked_in', v_ticket_id, v_booking_id, 'checked_in',
    v_checked_in_at, v_passenger_name, v_route_departure, v_route_destination;
end;
$$;

grant execute on function public.check_in_ticket(text, text) to authenticated;

-- ============================================================================
-- 11. OPTIONAL SEED DATA
-- Keep this section only if you want sample data in a fresh project.
-- ============================================================================
insert into public.routes (transport_type, departure, destination, departure_time, arrival_time)
values
  ('Train', 'Hanoi', 'Da Nang', '08:15', '14:20'),
  ('Flight', 'Ho Chi Minh City', 'Singapore', '09:45', '12:35'),
  ('Train', 'Hue', 'Nha Trang', '21:25', '05:40'),
  ('Bus', 'Hanoi', 'Hai Phong', '06:30', '09:00'),
  ('Flight', 'Hanoi', 'Ho Chi Minh City', '14:00', '15:45');

insert into public.vehicles (route_id, vehicle_code, vehicle_type, capacity, deck_layout)
select
  routes.id,
  'VEH-' || row_number() over (order by routes.id),
  case
    when routes.transport_type = 'Train' then 'Coach'
    when routes.transport_type = 'Flight' then 'Aircraft'
    else 'Bus'
  end,
  case
    when routes.transport_type = 'Train' then 108
    when routes.transport_type = 'Flight' then 180
    else 54
  end,
  jsonb_build_object(
    'seat_columns', 9,
    'layout', '3-3-3',
    'aisles', jsonb_build_array(3, 6)
  )
from public.routes;

insert into public.seats (
  vehicle_id,
  seat_code,
  seat_class,
  status,
  position_meta
)
select
  vehicles.id,
  chr(64 + ceil(seat_num::numeric / 9)::int) || (((seat_num - 1) % 9) + 1)::text as seat_code,
  case ((seat_num - 1) % 9) + 1
    when 1 then 'window'
    when 2 then 'middle'
    when 3 then 'aisle'
    when 4 then 'aisle'
    when 5 then 'middle'
    when 6 then 'aisle'
    when 7 then 'aisle'
    when 8 then 'middle'
    when 9 then 'window'
  end as seat_class,
  'available' as status,
  jsonb_build_object(
    'row', ceil(seat_num::numeric / 9)::int,
    'col', ((seat_num - 1) % 9) + 1,
    'x', case
      when ((seat_num - 1) % 9) + 1 between 1 and 3
        then 20 + (((seat_num - 1) % 9)) * 70
      when ((seat_num - 1) % 9) + 1 between 4 and 6
        then 260 + (((seat_num - 1) % 9) - 3) * 70
      else 500 + (((seat_num - 1) % 9) - 6) * 70
    end,
    'y', (ceil(seat_num::numeric / 9)::int - 1) * 70 + 20
  ) as position_meta
from public.vehicles,
     lateral generate_series(1, public.vehicles.capacity) as seat_series(seat_num)
where public.vehicles.capacity <= 234
order by public.vehicles.id, seat_num;

-- ============================================================================
-- 12. SETUP NOTES
-- ============================================================================
-- 1. Run this file on a fresh Supabase project.
-- 2. Create at least one auth user, then insert/update the matching profile row.
-- 3. Promote an admin when needed:
--    update public.profiles set role = 'admin' where email = 'your-admin-email@example.com';
-- 4. Enable Google OAuth or other auth providers in Supabase if your app uses them.
-- 5. Set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY in your frontend environment.
