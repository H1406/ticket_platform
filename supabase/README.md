# Supabase Configuration

This directory contains all database-related files for the ticket platform.

## Files

- **`schema.sql`** - Complete database schema (all tables, RLS, seed data in one file)
- **`migrations/`** - Individual migration scripts (can be run step-by-step)
- **`migrations/README.md`** - Detailed migration instructions

## Quick Start

**Fastest way to set up your database:**

1. Copy entire contents of `schema.sql`
2. Paste into [Supabase SQL Editor](https://app.supabase.com) → New Query
3. Click "Run"
4. Done! ✅

See [../QUICKSTART.md](../QUICKSTART.md) for detailed steps.

## Database Structure

```
Profiles (Auth Users)
  ├── Routes
  │   └── Vehicles
  │       └── Seats
  ├── Bookings
  │   └── Tickets
  │       └── Check-ins
  └── Notifications
```

## Key Features

- ✅ **Row Level Security (RLS)** - Users see only their data
- ✅ **Relationships** - Proper foreign keys with cascading deletes
- ✅ **Indexes** - Performance optimized queries
- ✅ **Sample Data** - 5 routes, 5 vehicles, 100 seats
- ✅ **Admin Policies** - Separate permissions for admin users

## Environment Variables

Required in `.env`:

```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
VITE_SOCKET_URL=http://localhost:3001
```

## Support

For issues or questions:

1. Check [migrations/README.md](./migrations/README.md)
2. Check [../QUICKSTART.md](../QUICKSTART.md)
3. Review Supabase documentation: https://supabase.com/docs
