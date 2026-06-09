-- Create tickets table
create table public.tickets (
  id uuid default gen_random_uuid() primary key,
  booking_id uuid not null references public.bookings on delete cascade,
  qr_payload text,
  boarding_status text default 'not_boarded',
  issued_at timestamp with time zone default timezone('utc'::text, now()) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.tickets enable row level security;

-- Create policies
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

-- Create indexes
create index tickets_booking_id_idx on public.tickets(booking_id);
create index tickets_boarding_status_idx on public.tickets(boarding_status);
