# TransitFlow

Frontend-first MVP scaffold for a real-time railway and flight booking platform built with Vue 3, Vite, Vue Router, Pinia, Bootstrap 5, Axios, Socket.IO client, and Supabase placeholders.

## Quick start

1. Install dependencies:

```bash
npm install
```

2. Copy environment variables:

```bash
cp .env.example .env
```

3. Run the app:

```bash
npm run dev
```

## Included MVP scope

- Marketing landing page
- Supabase-ready authentication flow
- Protected dashboard routes
- Search routes UI with mock results
- Interactive SVG seat map scaffold
- Digital ticket view
- Admin operations dashboard
- Realtime-ready service/composable placeholders

## Supabase placeholders

Set these values in `.env`:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`
- `VITE_SOCKET_URL`

## Future-ready notes

- Realtime seat locking is intentionally mocked for now
- Booking APIs are stubbed behind reusable service modules
- Socket.IO structure is prepared for event broadcasting and notification streaming
