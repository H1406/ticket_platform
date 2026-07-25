# TransitFlow

Web platform for transportation ticket purchasing with realtime-ready booking flows, separate frontend/backend layers, and Supabase authentication placeholders.

## Structure

- `src/`: Vue frontend, layouts, stores, and client-side routing
- `backend/`: Express API, route modules, and controllers
- `shared/`: shared mock data used by both frontend and backend
- `supabase/`: database migrations and schema assets

## Local development

Install dependencies:

```bash
npm install
```

Run the frontend:

```bash
npm run dev:frontend
```

Run the backend in a second terminal:

```bash
npm run dev:backend
```

## Environment

Create `.env` from `.env.example` and configure:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`
- `VITE_APP_ORIGIN`
- `VITE_API_URL`
- `VITE_SOCKET_URL`
- `SERVER_PORT`
- `CLIENT_ORIGIN`

For deployed Google OAuth, set `VITE_APP_ORIGIN` to your public frontend origin, for example `https://your-app.vercel.app`. In Supabase Dashboard > Authentication > URL Configuration, set Site URL to the same origin and add `https://your-app.vercel.app/callback` to Redirect URLs.

## Backend route layout

- `GET /api/health`
- `GET /api/auth/status`
- `GET /api/dashboard/summary`
- `GET /api/routes/search`
- `GET /api/routes/:routeId/seats`
- `GET /api/bookings`
- `POST /api/bookings`
- `GET /api/bookings/checkins`
- `GET /api/bookings/tickets/:ticketId`

## Notes

- The frontend still uses Pinia mock state for the UI-first MVP
- The new backend is ready for you to move search, bookings, tickets, and admin data out of the client incrementally
- Vite proxies `/api` requests to `http://localhost:3001` during local development
