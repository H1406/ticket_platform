alter table public.bookings
  add column if not exists travel_date date;

update public.bookings
set travel_date = created_at::date
where travel_date is null;

alter table public.bookings
  alter column travel_date set not null;

create index if not exists bookings_travel_date_idx on public.bookings(travel_date);
create index if not exists bookings_route_travel_date_idx on public.bookings(route_id, travel_date);

-- Seat rows represent physical inventory. Confirmed bookings now provide the
-- durable date-specific reservation state through bookings.seat_ids.
update public.seats
set
  status = 'available',
  held_by_booking_id = null,
  held_by_user_id = null,
  hold_expires_at = null
where status = 'booked';

drop function if exists public.hold_seat(uuid, uuid, uuid, integer);
drop function if exists public.confirm_booking(uuid);

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
  v_seat record;
  v_travel_date date := coalesce(p_travel_date, timezone('utc'::text, now())::date);
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

  insert into public.checkins (ticket_id, gate, agent_id)
  values (v_ticket_id, p_gate, auth.uid())
  returning checked_in_at into v_checked_in_at;

  update public.tickets
  set boarding_status = 'checked_in'
  where id = v_ticket_id;

  return query select
    'checked_in', v_ticket_id, v_booking_id, 'checked_in',
    v_checked_in_at, v_passenger_name, v_route_departure, v_route_destination;
end;
$$;

grant execute on function public.hold_seat(uuid, uuid, uuid, integer, date) to authenticated;
grant execute on function public.confirm_booking(uuid, date) to authenticated;
grant execute on function public.check_in_ticket(text, text) to authenticated;
