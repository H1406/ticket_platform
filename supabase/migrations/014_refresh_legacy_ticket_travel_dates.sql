-- Earlier demo bookings did not let users choose a travel date, so their
-- travel_date was backfilled from created_at. Move still-unchecked legacy
-- tickets onto the next available run for the same daily schedule.
update public.bookings b
set travel_date =
  case
    when coalesce(r.departure_time, '00:00'::time) <= timezone('utc'::text, now())::time
      then timezone('utc'::text, now())::date + 1
    else timezone('utc'::text, now())::date
  end
from public.routes r
where r.id = b.route_id
  and b.status = 'confirmed'
  and (
    b.travel_date::timestamp + coalesce(r.departure_time, '00:00'::time)
  ) < timezone('utc'::text, now())
  and not exists (
    select 1
    from public.tickets t
    join public.checkins c on c.ticket_id = t.id
    where t.booking_id = b.id
  );
