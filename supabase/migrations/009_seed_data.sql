-- Seed routes
insert into public.routes (transport_type, departure, destination, departure_time, arrival_time)
values
  ('Train', 'Hanoi', 'Da Nang', '08:15', '14:20'),
  ('Flight', 'Ho Chi Minh City', 'Singapore', '09:45', '12:35'),
  ('Train', 'Hue', 'Nha Trang', '21:25', '05:40'),
  ('Bus', 'Hanoi', 'Hai Phong', '06:30', '09:00'),
  ('Flight', 'Hanoi', 'Ho Chi Minh City', '14:00', '15:45');

-- Seed vehicles (assuming routes exist)
insert into public.vehicles (route_id, vehicle_code, vehicle_type, capacity, deck_layout)
select 
  r.id,
  'VEH-' || row_number() over (order by r.id),
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
from public.routes r;

-- Seed seats for the first vehicle
insert into public.seats (vehicle_id, seat_code, seat_class, status, position_meta)
with vehicle_seats as (
  select 
    v.id,
    chr(64 + row_number() over (order by seats.letter)::int) || seats.number::text as seat_code,
    case 
      when (row_number() over (order by seats.letter)::int) in (1, 4) then 'window'
      else 'aisle'
    end as seat_class,
    case 
      when random() < 0.1 then 'booked'
      when random() < 0.15 then 'held'
      else 'available'
    end as status,
    jsonb_build_object(
      'x', ((row_number() over (order by seats.letter)::int - 1) * 80 + 40)::int,
      'y', (seats.number * 80 + 40)::int
    ) as position_meta
  from public.vehicles v,
       lateral (
         select generate_series(1, 4) as letter,
                generate_series(1, 12) as number
       ) as seats
  where v.vehicle_type = 'Coach'
  limit 1
)
select * from vehicle_seats;

-- Seed notifications (sample data for demo)
-- Note: In production, these would be created by your backend
insert into public.notifications (user_id, title, message, channel)
select 
  p.id,
  'Booking Confirmation',
  'Your ticket is confirmed. Check your email for details.',
  'in-app'
from public.profiles p
limit 1;

-- Create admin profile (if needed for testing)
-- Note: Run this after creating a user via auth
-- insert into public.profiles (id, email, first_name, last_name, role)
-- values ('YOUR_AUTH_USER_ID', 'admin@example.com', 'Admin', 'User', 'admin');
