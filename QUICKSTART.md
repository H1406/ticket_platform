# Quick Start: Database Setup

## 🚀 Fastest Way (Copy & Paste)

1. **Open Supabase Dashboard**: https://app.supabase.com → Select your project

2. **Go to SQL Editor** and click "New query"

3. **Copy entire contents of `schema.sql`** from your project:
   - File: `/supabase/schema.sql`

4. **Paste into Supabase SQL Editor** and click "Run"

5. **Done!** All tables, policies, and sample data are created.

---

## ✅ Verification Steps

After running the schema, verify everything was created:

```sql
-- List all tables
SELECT * FROM information_schema.tables WHERE table_schema = 'public';

-- Check profiles table
SELECT COUNT(*) FROM public.profiles;

-- Check routes table
SELECT COUNT(*) FROM public.routes;

-- Check seats table
SELECT COUNT(*) FROM public.seats;
```

---

## 🔐 Set Up Admin User

After you sign up via Google OAuth:

1. **Get your email** from your auth account
2. **Run this in Supabase SQL Editor**:
   ```sql
   UPDATE public.profiles
   SET role = 'admin'
   WHERE email = 'your-email@example.com';
   ```

---

## 🔑 Update .env File

Make sure your `.env` file has the correct values:

```bash
VITE_SUPABASE_URL=https://your-project-id.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
VITE_SOCKET_URL=http://localhost:3001
```

Find these in **Supabase Dashboard > Project Settings > API**

---

## 📋 What Gets Created

| Table         | Rows | Purpose                            |
| ------------- | ---- | ---------------------------------- |
| profiles      | 0    | User profiles (extended from auth) |
| routes        | 5    | Transportation routes              |
| vehicles      | 5    | Vehicles assigned to routes        |
| seats         | 100  | Seats with positions               |
| bookings      | 0    | User bookings                      |
| tickets       | 0    | Issued tickets                     |
| checkins      | 0    | Check-in records                   |
| notifications | 0    | User notifications                 |

---

## 🛑 Troubleshooting

**Error: "permission denied for schema public"**
→ Use Supabase Dashboard SQL Editor (not psql)

**Error: "relation already exists"**
→ Tables already created; it's safe to ignore

**No data after running seed**
→ Seed data is optional; start by creating a booking manually

---

## 📚 Individual Migration Files

If you prefer running migrations one-by-one:

```bash
# migrations/ directory contains individual files
supabase/migrations/001_create_profiles.sql
supabase/migrations/002_create_routes.sql
# ... etc
```

**Run in order** (001 → 009) in Supabase SQL Editor.

---

## Next Steps

1. ✅ Run `schema.sql`
2. ✅ Set up admin user
3. ✅ Update `.env`
4. ✅ Restart dev server: `npm run dev`
5. ✅ Test: Sign in with Google → check dashboard

See [migrations/README.md](./migrations/README.md) for detailed documentation.
