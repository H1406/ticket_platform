-- Create checkins table
create table public.checkins (
  id uuid default gen_random_uuid() primary key,
  ticket_id uuid not null references public.tickets on delete cascade,
  checked_in_at timestamp with time zone default timezone('utc'::text, now()) not null,
  gate text,
  agent_id uuid references public.profiles on delete set null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.checkins enable row level security;

-- Create policies
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

-- Create indexes
create index checkins_ticket_id_idx on public.checkins(ticket_id);
create index checkins_agent_id_idx on public.checkins(agent_id);
create index checkins_checked_in_at_idx on public.checkins(checked_in_at);
