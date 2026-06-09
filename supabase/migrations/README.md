# Supabase Database Setup Instructions

This directory contains SQL migration scripts to set up the ticket platform database schema on Supabase PostgreSQL.

## Files Overview

1. **001_create_profiles.sql** - Creates the profiles table extending auth.users
2. **002_create_routes.sql** - Creates routes table for transportation routes
3. **003_create_vehicles.sql** - Creates vehicles table linked to routes
4. **004_create_seats.sql** - Creates seats table with position metadata
5. **005_create_bookings.sql** - Creates bookings table for user reservations
6. **006_create_tickets.sql** - Creates tickets table for issued boarding passes
7. **007_create_checkins.sql** - Creates checkins table for passenger verification
8. **008_create_notifications.sql** - Creates notifications table for user alerts
9. **009_seed_data.sql** - Seed data for testing and development

## How to Run Migrations

### Option 1: Using Supabase Dashboard (Recommended for quick setup)

1. Go to your Supabase project: https://app.supabase.com
2. Navigate to **SQL Editor**
3. Click **"New query"**
4. Copy the contents of each migration file in order (001 → 009)
5. Paste and execute each one (wait for completion before running the next)

### Option 2: Using Supabase CLI (Recommended for production)

```bash
# Install Supabase CLI if not already done
npm install -g supabase

# Link to your project
supabase link --project-id YOUR_PROJECT_ID

# Apply migrations
supabase db push

# Or run specific migrations
supabase db execute < supabase/migrations/001_create_profiles.sql
```

### Option 3: Running migrations manually via psql

```bash
# Get your database connection string from Supabase dashboard
# Then run:
psql YOUR_CONNECTION_STRING < supabase/migrations/001_create_profiles.sql
```

## Database Schema Overview

```
profiles (extends auth.users)
├── id (uuid, PK)
├── email
├── first_name
├── last_name
├── avatar_url
├── role (user | admin)

routes
├── id (uuid, PK)
├── transport_type
├── departure
├── destination
├── departure_time
└── arrival_time

vehicles
├── id (uuid, PK)
├── route_id (FK → routes)
├── vehicle_code
├── vehicle_type
├── capacity
└── deck_layout (jsonb)

seats
├── id (uuid, PK)
├── vehicle_id (FK → vehicles)
├── seat_code
├── seat_class
├── status (available | selected | reserved | occupied)
└── position_meta (jsonb)

bookings
├── id (uuid, PK)
├── user_id (FK → profiles)
├── route_id (FK → routes)
├── seat_ids (uuid[])
├── status (pending | confirmed | cancelled)
└── hold_expires_at

tickets
├── id (uuid, PK)
├── booking_id (FK → bookings)
├── qr_payload
├── boarding_status (not_boarded | boarded)
└── issued_at

checkins
├── id (uuid, PK)
├── ticket_id (FK → tickets)
├── checked_in_at
├── gate
└── agent_id (FK → profiles)

notifications
├── id (uuid, PK)
├── user_id (FK → profiles)
├── title
├── message
├── channel (in-app | email | sms)
└── read_at
```

## Row Level Security (RLS)

All tables have RLS enabled with the following policies:

- **profiles**: Public read, users can modify their own
- **routes**: Public read, admins only write
- **vehicles**: Public read, admins only write
- **seats**: Public read, users can update status
- **bookings**: Users see their own, admins see all
- **tickets**: Users see their own, admins see all
- **checkins**: Users see their own, admins can insert
- **notifications**: Users see their own

## Important Notes

1. **Enable Auth Extensions**: Make sure your Supabase project has the `uuid-ossp` extension enabled (usually done automatically)

2. **Admin User Setup**: After creating your first admin user via Google OAuth, you need to manually update their profile:

   ```sql
   update public.profiles
   set role = 'admin'
   where email = 'your-admin-email@example.com';
   ```

3. **Seed Data**: The seed script includes sample data. Run it for testing/development, but skip it for production.

4. **Authentication Required**: The app uses Supabase Auth with Google OAuth. Users must authenticate before their profile is created.

## Troubleshooting

**Error: "permission denied for schema public"**

- Make sure your Supabase service key is used (not the anon key) when running migrations manually

**Error: "relation already exists"**

- Tables are already created; skip to the next migration

**Foreign key constraint errors**

- Run migrations in order; ensure parent tables are created before child tables

## Next Steps

After running all migrations:

1. Set up Google OAuth credentials in your Supabase project
2. Update `.env` with your Supabase URL and anon key
3. Test the booking store with `npm run dev`
4. Create your first admin user and update their role
