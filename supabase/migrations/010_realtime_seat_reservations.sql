alter table public.seats
  add column if not exists held_by_booking_id uuid references public.bookings on delete set null,
  add column if not exists held_by_user_id uuid references public.profiles on delete set null,
  add column if not exists hold_expires_at timestamp with time zone;

update public.seats
set status = case
  when status in ('reserved', 'selected') then 'held'
  when status = 'occupied' then 'booked'
  else 'available'
end;

alter table public.seats
  drop constraint if exists seats_status_check;

alter table public.seats
  add constraint seats_status_check
  check (status in ('available', 'held', 'booked'));

update public.bookings
set status = case
  when status = 'pending' and hold_expires_at is not null then 'held'
  when status = 'pending' then 'draft'
  else status
end;

alter table public.bookings
  drop constraint if exists bookings_status_check;

alter table public.bookings
  add constraint bookings_status_check
  check (status in ('draft', 'held', 'confirmed', 'cancelled', 'expired'));

create index if not exists seats_held_by_booking_id_idx on public.seats(held_by_booking_id);
create index if not exists seats_held_by_user_id_idx on public.seats(held_by_user_id);
create index if not exists seats_hold_expires_at_idx on public.seats(hold_expires_at);
create index if not exists bookings_hold_expires_at_idx on public.bookings(hold_expires_at);

do $$
begin
  alter publication supabase_realtime add table public.seats;
exception
  when duplicate_object then null;
end;
$$;

drop policy if exists "Users can update seat status" on public.seats;

create policy "Users can update seat status"
  on public.seats for update
  using (auth.role() = 'authenticated')
  with check (
    auth.role() = 'authenticated'
    and status in ('available', 'held', 'booked')
  );

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc'::text, now());
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

drop trigger if exists set_routes_updated_at on public.routes;
create trigger set_routes_updated_at
before update on public.routes
for each row
execute function public.set_updated_at();

drop trigger if exists set_vehicles_updated_at on public.vehicles;
create trigger set_vehicles_updated_at
before update on public.vehicles
for each row
execute function public.set_updated_at();

drop trigger if exists set_seats_updated_at on public.seats;
create trigger set_seats_updated_at
before update on public.seats
for each row
execute function public.set_updated_at();

drop trigger if exists set_bookings_updated_at on public.bookings;
create trigger set_bookings_updated_at
before update on public.bookings
for each row
execute function public.set_updated_at();

drop trigger if exists set_tickets_updated_at on public.tickets;
create trigger set_tickets_updated_at
before update on public.tickets
for each row
execute function public.set_updated_at();

drop trigger if exists set_notifications_updated_at on public.notifications;
create trigger set_notifications_updated_at
before update on public.notifications
for each row
execute function public.set_updated_at();

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
  p_hold_minutes integer default 5
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
  v_seat record;
  v_hold_expires_at timestamp with time zone := timezone('utc'::text, now()) + make_interval(mins => greatest(1, least(p_hold_minutes, 10)));
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

  if v_seat.status = 'booked' then
    raise exception 'Seat is already booked';
  end if;

  if v_seat.status = 'held'
     and v_seat.hold_expires_at is not null
     and v_seat.hold_expires_at > timezone('utc'::text, now())
     and v_seat.held_by_user_id is distinct from v_user_id then
    raise exception 'Seat is currently held by another passenger';
  end if;

  if p_booking_id is not null then
    select id
    into v_booking_id
    from public.bookings
    where id = p_booking_id
      and user_id = v_user_id
      and route_id = p_route_id
    for update;
  end if;

  if v_booking_id is null then
    insert into public.bookings (user_id, route_id, seat_ids, status, hold_expires_at)
    values (v_user_id, p_route_id, array[p_seat_id], 'held', v_hold_expires_at)
    returning id into v_booking_id;
  end if;

  update public.seats
  set
    status = 'held',
    held_by_booking_id = v_booking_id,
    held_by_user_id = v_user_id,
    hold_expires_at = v_hold_expires_at
  where id = p_seat_id;

  update public.bookings
  set
    status = 'held',
    seat_ids = coalesce((
      select array_agg(id order by seat_code)
      from public.seats
      where held_by_booking_id = v_booking_id
        and status = 'held'
        and hold_expires_at > timezone('utc'::text, now())
    ), array[]::uuid[]),
    hold_expires_at = v_hold_expires_at
  where id = v_booking_id;

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

  select held_by_booking_id
  into v_booking_id
  from public.seats
  where id = p_seat_id
    and held_by_user_id = v_user_id
    and status = 'held'
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
  where id = p_seat_id
    and held_by_user_id = v_user_id
    and status = 'held';

  if v_booking_id is not null then
    update public.bookings
    set
      seat_ids = coalesce((
        select array_agg(id order by seat_code)
        from public.seats
        where held_by_booking_id = v_booking_id
          and status = 'held'
          and hold_expires_at > timezone('utc'::text, now())
      ), array[]::uuid[]),
      hold_expires_at = (
        select max(hold_expires_at)
        from public.seats
        where held_by_booking_id = v_booking_id
          and status = 'held'
      ),
      status = case
        when exists (
          select 1 from public.seats
          where held_by_booking_id = v_booking_id
            and status = 'held'
        ) then 'held'
        else 'draft'
      end
    where id = v_booking_id
      and user_id = v_user_id;
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
  where held_by_booking_id = p_booking_id
    and held_by_user_id = v_user_id
    and status = 'held';

  get diagnostics released_count = row_count;

  update public.bookings
  set
    seat_ids = array[]::uuid[],
    hold_expires_at = null,
    status = case when p_cancel then 'cancelled' else 'draft' end
  where id = p_booking_id
    and user_id = v_user_id
    and status <> 'confirmed';

  return released_count;
end;
$$;

create or replace function public.confirm_booking(
  p_booking_id uuid
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
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  perform public.release_expired_seat_holds();

  perform 1
  from public.bookings
  where id = p_booking_id
    and user_id = v_user_id
    and status in ('held', 'draft')
  for update;

  if not found then
    raise exception 'Booking was not found';
  end if;

  perform 1
  from public.seats
  where held_by_booking_id = p_booking_id
    and held_by_user_id = v_user_id
    and status = 'held'
    and hold_expires_at > v_now
  for update;

  if not found then
    raise exception 'There are no active seat holds to confirm';
  end if;

  if exists (
    select 1
    from public.seats
    where held_by_booking_id = p_booking_id
      and (
        status <> 'held'
        or hold_expires_at is null
        or hold_expires_at <= v_now
      )
  ) then
    raise exception 'One or more seats are no longer available';
  end if;

  update public.bookings
  set
    status = 'confirmed',
    seat_ids = (
      select array_agg(id order by seat_code)
      from public.seats
      where held_by_booking_id = p_booking_id
        and status = 'held'
    ),
    hold_expires_at = null
  where id = p_booking_id
    and user_id = v_user_id;

  insert into public.tickets (booking_id, qr_payload, boarding_status)
  values (p_booking_id, null, 'not_boarded')
  returning id into v_ticket_id;

  update public.tickets
  set qr_payload = v_ticket_id::text
  where id = v_ticket_id;

  update public.seats
  set
    status = 'booked',
    hold_expires_at = null
  where held_by_booking_id = p_booking_id
    and held_by_user_id = v_user_id
    and status = 'held';

  return query
  select p_booking_id, v_ticket_id, v_ticket_id::text;
end;
$$;

grant execute on function public.release_expired_seat_holds() to authenticated, anon;
grant execute on function public.hold_seat(uuid, uuid, uuid, integer) to authenticated;
grant execute on function public.release_seat_hold(uuid, uuid) to authenticated;
grant execute on function public.release_booking_holds(uuid, boolean) to authenticated;
grant execute on function public.confirm_booking(uuid) to authenticated;
