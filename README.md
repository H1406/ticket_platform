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

Run the assistant API in a second terminal:

```bash
npm run dev:assistant
```

## Environment

Create `.env` from `.env.example` and configure:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`
- `VITE_APP_ORIGIN`
- `VITE_API_URL`
- `VITE_SOCKET_URL`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `DEEPSEEK_API_KEY` (placeholder is supported; without a real key the assistant uses deterministic slot parsing)
- `DEEPSEEK_MODEL` (optional, defaults to `deepseek-v4-pro`)

Install the assistant API Python dependencies when running DeepSeek locally:

```bash
python3 -m pip install -r assistant_api/requirements.txt
```

For deployed Google OAuth, set `VITE_APP_ORIGIN` to your public frontend origin, for example `https://your-app.vercel.app`. In Supabase Dashboard > Authentication > URL Configuration, set Site URL to the same origin and add `https://your-app.vercel.app/callback` to Redirect URLs.

## Assistant API

The booking assistant runs at `POST /api/assistant` through `assistant_api/api.py`.
It uses the signed-in user's Supabase bearer token, fetches routes and seat status through Supabase REST, holds seats with `hold_seat`, returns a confirmation payload, then calls `confirm_booking` after the user confirms.

The assistant's SQL-style tools currently cover:

- Current user/profile lookup
- Route lookup
- Seat status lookup for the selected route vehicle
- Confirmed booking lookup for the requested travel date
- Seat holding and booking confirmation through existing Supabase RPCs

## Legacy backend route layout

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
