-- Allow admins to update ticket boarding status directly (RLS previously only allowed the
-- owning user to update their own ticket, which blocks admin-driven check-in flows).
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

-- Atomic, admin-only ticket check-in from a scanned QR payload.
-- Looks the ticket up by qr_payload (falling back to the ticket id itself, since
-- confirm_booking() sets qr_payload = ticket id), validates expiry and duplicate
-- check-in, then inserts a checkins row and flips boarding_status in one transaction.
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

grant execute on function public.check_in_ticket(text, text) to authenticated;
