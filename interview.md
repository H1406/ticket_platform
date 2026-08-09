## Ticket Platform Interview Cheat Sheet

### 1. Project Summary
- **Name:** TransitFlow / ticket_platform
- **Stack:** Vue 3 + Vite + Pinia + Vue Router + Bootstrap CSS + Supabase + html5-qrcode
- **Purpose:** Transportation ticket booking and boarding pass management with user tickets and admin QR check-in.
- **Frontend:** src
- **Backend/assistant API:** api.py
- **Database schema + migrations:** supabase

---

## 2. Frontend Architecture

### Entry point
- main.js
  - creates Vue app
  - installs Pinia
  - installs Vue Router
  - loads Bootstrap CSS and custom styles

### Routing
- index.js
- Routes:
  - `/` → `LandingView.vue`
  - `/auth` → `AuthView.vue`
  - `/dashboard` → `DashboardView.vue`
  - `/search` → `SearchRoutesView.vue`
  - `/seat-selection` → `SeatSelectionView.vue`
  - `/ticket` → TicketView.vue
  - `/admin` → `AdminDashboardView.vue`
  - `/admin/tickets` → AdminTicketsView.vue
- Guards:
  - `requiresAuth`
  - `guestOnly`
  - `requiresAdmin`

### Layouts
- MainLayout.vue
- AdminLayout.vue
- AuthLayout.vue

---

## 3. State Management

### Pinia store
- booking.js
- Main responsibilities:
  - route and seat loading
  - booking hold flow
  - ticket fetching
  - admin ticket management
  - realtime subscriptions
  - QR check-in mutation

### Auth store
- auth.js (not read but used in router and booking store)
- likely handles user/profile and admin flag

---

## 4. Ticket UI & Workflows

### User ticket page
- TicketView.vue
- Shows:
  - list of user tickets
  - selected ticket detail panel
  - ticket QR code
  - boarding/check-in status
  - expiry state
- Direct-link support:
  - `/ticket?ticketId=<id>`
  - selects ticket from query string
- States handled:
  - loading
  - error
  - empty list
  - selected ticket absent

### Ticket components
- TicketListItem.vue
  - compact selectable ticket row
- TicketCard.vue
  - detail panel with QR image
  - route, passenger, seat, departure, arrival, ticket IDs
- TicketStatusBadge.vue
  - status badge with expired / checked in / pending visuals

### Ticket data mapping
- `TICKET_ROW_SELECT` in booking.js
  - joins `tickets`, `bookings`, `routes`, `profiles`, `checkins`
- `mapTicketRows(...)`
  - resolves seat codes, QR payload, timeline status
- `resolveTicketQr(...)`
  - uses `generateTicketQrAssets` from ticketQr.js

---

## 5. Admin Ticket Operations

### Admin ticket page
- AdminTicketsView.vue
- Components:
  - QrScannerPanel.vue
  - AdminTicketsTable.vue

### Table features
- shows all tickets
- columns:
  - ticket id
  - passenger
  - route
  - seat
  - travel date
  - departure time
  - boarding status
  - expiry status
  - last check-in
- filter/search:
  - by id / passenger / route
  - by status: all, valid, checked in, expired, cancelled

### QR scanner
- QrScannerPanel.vue
- Uses `html5-qrcode`
- Controls:
  - Start scanner
  - Stop scanner
  - Retry on error/denied
- Scanning flow:
  - camera access requested on demand
  - pause scanner after scan
  - call `bookingStore.checkInTicketFromQr(decodedText)`
  - resume scanner after result delay
- Result states:
  - checked_in
  - already_checked_in
  - expired
  - not_found
  - error
- Cleanup:
  - stops scanner on component unmount

### Admin data actions
- `fetchAdminTickets()`
- `checkInTicketFromQr(qrPayload)`
- `fetchPassengerCheckInFeed()`
- realtime subscription to `checkins` via `supabase.channel('admin-checkins')`

---

## 6. Realtime Seat Status Tracking

### Realtime channel
- `subscribeToSeatUpdates()` in booking.js
- Uses Supabase realtime on `seats` table filtered by active vehicle:
  - `filter: vehicle_id=eq.<activeVehicleId>`

### Seat map flow
- `fetchSeatMap(routeId, travelDate)`
  - releases expired holds by calling RPC `release_expired_seat_holds`
  - loads seats for vehicle
  - loads confirmed bookings for selected route/travel date
  - merges `booked` seat state
- `toggleSeat(seatId)`
  - holds or releases seat via Supabase RPC
  - updates local seat map after mutation

### Seat mapping
- `mapSeatRecord(...)`
  - normalizes seat metadata and hold state
  - detects holds held by current user
- Seat state values:
  - `available`
  - `held`
  - `booked`

---

## 7. Backend / Assistant API

### api.py
- Python ASGI app with manual request parsing
- Supports:
  - token extraction
  - environment loading
  - travel date/departure parsing
  - booking validation helpers
- Uses `httpx` + OpenAI / DeepSeek generator placeholders
- Not a full Express backend; serves assistant function and API route scaffolding

### Local dev
- `npm run dev:frontend` → Vite
- `npm run dev:assistant` → `uvicorn assistant_api.api:app`
- Vite proxy likely routes to backend at `http://localhost:3001`

---

## 8. Supabase Schema Notes

### Important tables
- 006_create_tickets.sql
- 007_create_checkins.sql
- 013_add_booking_travel_date.sql
- 014_refresh_legacy_ticket_travel_dates.sql
- 012_ticket_checkin.sql

### Key domain objects
- `routes`
  - departure, destination, departure_time, arrival_time
- `vehicles`
  - route assignment, capacity, deck_layout
- `seats`
  - vehicle_id, seat_code, seat_class, status, held_by_booking_id, held_by_user_id, hold_expires_at
- `bookings`
  - user_id, route_id, seat_ids, status, travel_date
- `tickets`
  - booking_id, qr_payload, boarding_status, issued_at
- `checkins`
  - ticket_id, checked_in_at, gate, agent_id

### Expiry logic
- Ticket expiry is based on:
  - `travel_date`
  - `departure_time`
- computed consistently in ticketTimeline.js
  - shared helper for `isExpired`, `canCheckIn`, `isCheckedIn`
- Expired tickets:
  - show expired label
  - block check-in
  - remain visible in admin table

---

## 9. Vue & Responsive UI Notes

### Responsive patterns
- TicketView.vue layout:
  - two-column on desktop: ticket list + detail
  - stacked on mobile via Bootstrap grid
- TicketCard.vue and TicketListItem.vue
  - use glass-panel styles and responsive card layout
- AdminTicketsView.vue
  - scanner panel and filter panel share row layout
  - table inside `.table-responsive`

### UX patterns
- clear loading / error / empty states
- actionable button flows:
  - Download QR
  - Search routes
  - Start/stop scanner
- selected ticket visually highlighted in list
- status badge consistency via TicketStatusBadge.vue

### Realtime UI behavior
- seat map updates automatically via Supabase channel
- check-in feed refreshes on `checkins` changes
- holds / booking state refreshed after seat toggles

---

## 10. Key talking points for interview

- **Frontend separation:** route-based views + reusable ticket components
- **State layer:** Pinia store centralizes booking, ticket, admin, and realtime logic
- **Realtime updates:** Supabase realtime channels for seat map and admin check-in feed
- **QR check-in:** `html5-qrcode` used to scan camera QR codes in browser
- **Supabase data joins:** ticket list built from `tickets` + `bookings` + `routes` + `profiles` + `checkins`
- **Expiry logic:** shared helper keeps time comparisons consistent
- **API helper:** Python assistant API validates travel dates and can be extended for booking assistant flows
- **UX:** mobile-friendly Bootstrap grid + glass-panel UI + explicit states

---

## 11. Useful file map

- TicketView.vue
- `src/components/ticket/*`
- AdminTicketsView.vue
- QrScannerPanel.vue
- AdminTicketsTable.vue
- booking.js
- supabase.js
- index.js
- api.py
- `supabase/migrations/*`

If you want, I can also make a shorter one-page summary version for quick review.