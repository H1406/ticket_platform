-- Create notifications table
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

-- Enable RLS
alter table public.notifications enable row level security;

-- Create policies
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

-- Create indexes
create index notifications_user_id_idx on public.notifications(user_id);
create index notifications_read_at_idx on public.notifications(read_at);
create index notifications_created_at_idx on public.notifications(created_at);
