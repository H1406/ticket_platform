# TransitFlow Project Report

## 1. Project Overview

TransitFlow is a transportation ticketing web application that lets passengers search routes, select seats in realtime, reserve tickets, view QR-based boarding passes, and let administrators monitor ticket and boarding operations. The project is designed around a realistic ticket-purchase workflow rather than a static demo: routes, vehicles, seats, bookings, tickets, check-ins, notifications, authentication, and role-based access are all modeled as separate parts of the system.

The current project uses a Vue 3 frontend, Supabase for authentication/database/realtime features, and a Python assistant API for conversational ticket booking. The app supports both a manual booking flow and an automated ticket-ordering assistant. The manual flow lets users browse routes and select seats visually, while the assistant flow lets users request a trip in natural language and have the system search routes, select seats, place temporary holds, and confirm a booking after user approval.

The most important implemented feature is realtime seat status tracking. Seats can be available, temporarily held, or unavailable because they are part of a confirmed booking for a selected travel date. Supabase Realtime subscriptions keep connected clients synchronized when seat holds change, and Postgres functions protect the booking workflow from double booking.

## 2. Main Functionality

### 2.1 Authentication and User Roles

TransitFlow uses Supabase Authentication with Google OAuth support. The frontend exchanges OAuth callback data for a Supabase session, stores the authenticated user in Pinia, and loads the user's profile from the `profiles` table.

Each profile contains identity and role information, including:

- Email
- First name
- Last name
- Avatar URL
- Role

The role field is used to distinguish normal passengers from administrators. Vue Router protects authenticated pages and redirects users based on their session state. Admin routes require both authentication and an admin profile role.

Protected passenger features include:

- User dashboard
- Route search
- Seat selection
- Ticket view
- Booking assistant chat

Protected admin features include:

- Admin dashboard
- Ticket operations page
- QR check-in scanner
- Passenger check-in feed

### 2.2 Route Search

Passengers can search route inventory by departure, destination, departure date, passenger count, vehicle type, transport type, and time of day. Route data is loaded from Supabase through the booking store. Each route is joined with its assigned vehicle, so the UI can display route timing, transport mode, vehicle code, vehicle type, capacity, and layout information.

The route search screen also prevents invalid booking attempts. If a selected route has already departed for the chosen date, the UI blocks the passenger from entering the seat-selection flow. This avoids creating seat holds for trips that can no longer be booked.

### 2.3 Manual Seat Selection

The manual booking flow includes an interactive SVG seat map. Seats are drawn from the `seats` table and positioned using each seat's `position_meta` coordinates. The seat map displays different visual states for:

- Available seats
- Seats held by another passenger
- Seats held by the current passenger
- Seats already booked for the selected route and date

When a passenger clicks a seat, the app calls Supabase stored procedures to either hold or release the seat. A reservation timer shows the remaining hold time. The default hold duration is five minutes, and the database function limits the allowed hold duration so a client cannot create unusually long locks.

The seat selection sidebar summarizes:

- Passenger name and email
- Route operator and vehicle
- Departure and destination
- Travel date
- Selected seats
- Current realtime hold count
- Booking errors, if any

### 2.4 Booking Confirmation

After selecting seats, the passenger can confirm the booking. Confirmation is handled by the `confirm_booking` Supabase function. This function validates that:

- The user is authenticated.
- The booking belongs to the current user.
- The booking is still in a holdable state.
- The selected seats are still actively held.
- The hold has not expired.
- No other confirmed booking already owns the same seats for the same route and travel date.

If the checks pass, the function marks the booking as `confirmed`, persists the selected `seat_ids`, creates a ticket, and sets the ticket QR payload to the ticket ID. The frontend then loads the ticket and refreshes dashboard, booking history, notification, live-stat, and seat-map data.

### 2.5 Ticket View and QR Codes

Confirmed tickets are displayed with passenger, route, timing, seat, and boarding information. The app generates QR code assets on the client from the ticket payload using the `qrcode` package.

Ticket data includes:

- Ticket ID
- Booking ID
- Passenger name and email
- Departure and destination
- Travel date
- Departure and arrival time
- Seat codes
- Boarding status
- QR payload and rendered QR image
- Timeline status such as valid, checked in, or expired

### 2.6 Passenger Dashboard

The dashboard gives users a quick view of their activity. It loads trips, booking history, live platform stats, and notifications from Supabase through the booking store.

The dashboard helps passengers see:

- Upcoming trips
- Recent bookings
- Notifications
- Current ticket or trip status
- Live counts such as bookings, confirmed tickets, held seats, and issued tickets

### 2.7 Admin Dashboard

The admin dashboard provides an operations overview for staff. Admins can select an operations date and view metrics such as:

- Tickets sold
- Tickets ready for check-in
- Checked-in passengers
- Expired tickets
- Seat fill percentage
- Passenger boarding feed

The admin dashboard subscribes to check-in changes through Supabase Realtime. When a ticket is scanned and a check-in row is created, the admin feed and ticket metrics refresh without requiring a full page reload.

### 2.8 QR Check-In

The admin ticket operations page includes a camera-based QR scanner using `html5-qrcode`. When an admin scans a ticket, the frontend sends the QR payload to the `check_in_ticket` Supabase function.

The check-in function:

- Requires admin privileges.
- Looks up the ticket by `qr_payload` or ticket ID.
- Rejects unknown tickets.
- Detects duplicate check-ins.
- Blocks expired tickets after departure.
- Inserts a row in `checkins`.
- Updates the ticket's `boarding_status` to `checked_in`.

This makes check-in atomic and reliable because ticket lookup, validation, check-in creation, and boarding-status update are handled together at the database level.

### 2.9 Automated Ticket-Ordering Assistant

TransitFlow now includes an implemented assistant API for automated ticket ordering. The assistant appears in the frontend as a floating booking chat window. Users can ask for a booking in natural language, such as a route, travel date, and number of passengers.

The assistant API runs from `assistant_api/api.py` through Uvicorn and is exposed through Vite's `/api` proxy at `POST /api/assistant`. The frontend sends:

- The latest user message
- Conversation history
- Assistant state from previous turns
- The signed-in user's Supabase bearer token

The assistant can:

- Extract booking details from natural language.
- Ask for missing information such as departure city, destination, travel date, or ticket count.
- Use DeepSeek through an OpenAI-compatible client when `DEEPSEEK_API_KEY` is configured.
- Fall back to deterministic regex parsing when no real DeepSeek key is provided.
- Fetch the signed-in Supabase user.
- Look up routes from Supabase REST.
- Fetch vehicle seats.
- Check confirmed bookings for the requested travel date.
- Choose available seats, preferring adjacent seats when possible.
- Hold selected seats using the existing `hold_seat` Supabase RPC.
- Return a confirmation payload to the user.
- Confirm the booking through `confirm_booking` after the user replies yes.
- Cancel or abandon a pending assistant booking when the user asks to stop.

This means the automated agent is not separate from the main booking system. It uses the same Supabase functions and seat rules as the manual UI, which keeps both workflows consistent.

## 3. Technical Components and Tools Used

### 3.1 Frontend Stack

The frontend is built with:

- Vue 3 for component-based UI development
- Vite for local development, build tooling, and API proxying
- Vue Router for navigation and route guards
- Pinia for global application state
- Bootstrap 5 for grid and base interface styling
- Custom CSS for the TransitFlow visual design
- Axios for API requests
- Supabase JavaScript client for auth, database access, RPC calls, and realtime subscriptions
- `qrcode` for ticket QR generation
- `html5-qrcode` for camera-based ticket scanning

The frontend is organized into:

- `views` for full pages
- `layouts` for main, auth, and admin shells
- `components` for reusable UI pieces
- `stores` for auth and booking state
- `services` for API and Supabase clients
- `composables` for reusable Vue logic
- `utils` for ticket QR and ticket timeline helpers

### 3.2 Assistant API

The current backend entry point is the Python assistant API. It runs with:

- Python
- Uvicorn
- `httpx` for Supabase REST and RPC calls
- `python-dotenv` for environment loading
- OpenAI-compatible `openai` client for DeepSeek calls

The API supports:

- `GET /api/health`
- `POST /api/assistant`
- CORS preflight through `OPTIONS`

The assistant API reads these key environment variables:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `DEEPSEEK_API_KEY`
- `DEEPSEEK_MODEL`
- `ASSISTANT_HOLD_MINUTES`
- `DEEPSEEK_TIMEOUT_SECONDS`

If DeepSeek is not configured, the assistant still works through deterministic slot parsing. This makes local development easier because the booking assistant can be tested without a paid or external model key.

### 3.3 Legacy Express Backend

The repository still contains an older Express backend structure with route/controller modules and shared mock data. However, the current `package.json` scripts run the Python assistant API for backend development:

- `npm run dev:assistant`
- `npm run dev:backend`
- `npm run start:backend`

The Express files remain useful as historical scaffolding and route-contract references, but the active backend for the current project is the Python assistant API plus Supabase RPC/database logic.

### 3.4 Supabase Database

Supabase is the core backend platform. It provides:

- Authentication
- Postgres database storage
- Row Level Security
- Role-based access rules
- Realtime subscriptions
- REST access for the assistant API
- RPC functions for transactional booking operations

Important tables include:

- `profiles`
- `routes`
- `vehicles`
- `seats`
- `bookings`
- `tickets`
- `checkins`
- `notifications`

Important stored procedures include:

- `release_expired_seat_holds`
- `hold_seat`
- `release_seat_hold`
- `release_booking_holds`
- `confirm_booking`
- `check_in_ticket`

### 3.5 State Management

Pinia manages shared frontend state.

The `auth` store handles:

- Session initialization
- OAuth callback handling
- Supabase user loading
- Profile hydration
- Role detection
- Sign-in and sign-out behavior

The `booking` store handles:

- Route fetching
- Seat-map fetching
- Realtime seat subscriptions
- Seat holds and releases
- Booking confirmation
- Ticket loading
- User trip history
- Live stats
- Admin ticket lists
- Passenger check-in feed
- QR scan results

The assistant chat also keeps its own conversation state so multi-turn booking requests can continue across messages.

## 4. Realtime Seat Status Tracking

Realtime seat tracking is the project's most important technical feature because ticketing systems must prevent multiple passengers from selecting or confirming the same seat.

### 4.1 Seat Status Model

Each seat belongs to a vehicle and has a status:

- `available`: the seat can be selected.
- `held`: the seat is temporarily reserved during checkout.
- `booked`: the seat is unavailable in the current computed seat map because it is part of a confirmed booking.

The `seats` table stores temporary hold metadata:

- `held_by_booking_id`
- `held_by_user_id`
- `hold_expires_at`

These fields allow the system to identify whether a held seat belongs to the current user, another user, or an expired booking flow.

### 4.2 Loading Seat Availability

When the seat-selection page opens, the booking store loads the selected route, selected travel date, and active vehicle. It then calls `fetchSeatMap`.

The seat map is built from two sources:

- The `seats` table provides the physical seat layout and temporary hold status.
- The `bookings` table provides confirmed reservations for the selected route and travel date.

Before reading seat data, the app calls `release_expired_seat_holds`. This clears stale holds so abandoned booking flows do not keep seats unavailable.

The app then fetches all seats for the selected vehicle and separately fetches confirmed bookings for the same route and date. If a seat appears in a confirmed booking for that date, the frontend marks it as booked in the displayed seat map.

This design matters because the same physical vehicle layout may be reused on different travel dates. A seat booked today should not automatically be blocked for every future date.

### 4.3 Holding Seats

When a passenger clicks an available seat, the frontend calls the `hold_seat` Supabase function. The function performs the critical checks in the database:

- Authenticates the user.
- Releases expired holds first.
- Confirms that the seat belongs to the selected route.
- Locks the seat row for update.
- Checks whether the seat is confirmed for the selected travel date.
- Rejects seats actively held by another passenger.
- Creates or updates a held booking.
- Stores the hold owner and expiration timestamp on the seat.

Using database functions and row locks is safer than relying on frontend state because two clients can click the same seat at nearly the same time. The database becomes the source of truth.

### 4.4 Releasing Seats

Seats can be released in several ways:

- A passenger clicks a seat they already hold.
- The passenger cancels an active booking flow.
- The user leaves the seat-selection page.
- A hold expires.
- The assistant receives a cancel request.

The relevant functions are `release_seat_hold`, `release_booking_holds`, and `release_expired_seat_holds`. These functions clear temporary hold fields and update the booking state. If a held booking has no remaining held seats, it can return to draft, cancelled, or expired status depending on the flow.

### 4.5 Reservation Timer

The frontend stores the hold expiration timestamp returned by Supabase. The `ReservationTimer` component shows the remaining time. If the hold expires, the frontend reloads the seat map. Because `fetchSeatMap` calls `release_expired_seat_holds`, expired seats are cleaned up during refresh and become selectable again.

### 4.6 Supabase Realtime Channels

After a vehicle's seats are loaded, the booking store subscribes to a Supabase Realtime channel named:

```text
seat-map:{vehicleId}
```

The subscription listens for Postgres changes on the `seats` table filtered by `vehicle_id`. Whenever a seat row changes, the frontend refreshes the seat map.

Example realtime flow:

1. User A selects seat A1.
2. The `hold_seat` RPC marks A1 as held.
3. Supabase emits a realtime change for that seat row.
4. User B's browser receives the event.
5. User B's booking store reloads the seat map.
6. A1 appears as held and is no longer available to User B.

This keeps the seat canvas current across multiple active clients.

### 4.7 Confirmed Bookings and Date-Specific Availability

When a booking is confirmed, selected seat IDs are saved on the confirmed booking. The temporary hold fields on the physical seat rows are cleared.

This is intentional. Physical seats are reusable across dates, so the `seats` table should not become permanently locked after a single confirmed trip. Instead, confirmed bookings store which seats are sold for a specific route and travel date. The seat map then computes booked status from confirmed bookings for the currently selected date.

This approach supports:

- Recurring routes
- Multi-date schedules
- Reuse of the same vehicle layout
- Accurate future availability

### 4.8 Assistant Seat Tracking

The automated assistant uses the same seat model as the manual UI. Before selecting seats, it calls `release_expired_seat_holds`, fetches seats for the selected vehicle, checks confirmed bookings for the requested date, and chooses available seats.

For multiple passengers, the assistant attempts to select adjacent seats first. If adjacent seats are unavailable, it chooses the next available seats and explains that choice in the reply. It then calls `hold_seat` for each selected seat and returns a pending booking payload for confirmation.

Because the assistant uses the same Supabase RPCs as the manual flow, automated bookings still respect realtime seat locks, hold expiration, confirmed booking conflicts, and authenticated user ownership.

## 5. Innovative Features and Unique Approaches

### 5.1 Supabase-Backed Realtime Seat Holds

Seat selection is not only a visual frontend state. Seats are held through Supabase RPC functions and synchronized through Supabase Realtime. This gives the app production-like behavior where concurrent users see each other's seat interactions.

### 5.2 Date-Specific Seat Availability

The app separates physical seats from date-specific confirmed reservations. This avoids the common mistake of marking a physical seat as permanently booked after one trip. It makes the system more scalable for daily schedules and recurring services.

### 5.3 Automated Ticket-Ordering Agent

The assistant is a unique feature because it turns ticket ordering into a conversational workflow. It can parse a user's request, ask for missing details, choose seats, hold them, and confirm the booking after approval. The fallback regex parser also makes the assistant usable during local development without requiring an external model key.

### 5.4 Adjacent Seat Selection Logic

The assistant does more than pick random available seats. It sorts seats by code or layout coordinates and tries to find adjacent blocks for group bookings. If that is not possible, it still offers the next available seats and explains that adjacent seats were unavailable.

### 5.5 QR-Based Boarding Workflow

TransitFlow includes a complete digital-to-physical ticket lifecycle: confirmed booking, generated QR ticket, camera scan, validation, check-in record, and live admin update.

### 5.6 Realtime Admin Operations

The admin console is not only a static table. It shows ticket and boarding metrics by date and refreshes the passenger feed when check-ins happen.

## 6. Challenges and How They Were Addressed

### 6.1 Preventing Double Booking

The biggest challenge was preventing multiple users from reserving the same seat. This was addressed by moving important seat operations into Supabase Postgres functions. The functions validate ownership, lock rows, check confirmed bookings, and reject invalid holds or confirmations.

### 6.2 Handling Abandoned Holds

Passengers may close the browser, leave the page, or stop interacting before confirmation. TransitFlow solves this with expiration timestamps, cleanup RPCs, route-leave cleanup, page-hide cleanup, and assistant cancellation handling.

### 6.3 Supporting Both Manual and Automated Booking

The manual UI and automated assistant could easily become two separate systems. The project avoids that by making both flows use the same Supabase data model and RPC functions. The assistant acts as another client of the booking system rather than as a separate source of truth.

### 6.4 Keeping Availability Date-Aware

A physical seat can be reused on future dates, so confirmed booking logic needed to include `travel_date`. The project handles this by storing confirmed seat IDs on bookings and computing booked seats for the selected route/date combination.

### 6.5 Making the Assistant Useful Without a Model Key

The assistant can use DeepSeek when configured, but local development should not fail without that key. The project addresses this with a deterministic regex parser that can extract common route, date, passenger count, confirm, and cancel intents.

### 6.6 Browser Camera and QR Edge Cases

The QR scanner has to handle permission denial, unsupported browsers, duplicate scans, unknown tickets, and expired tickets. The UI manages camera state, while the `check_in_ticket` function returns clear statuses such as checked in, already checked in, expired, and not found.

## 7. Current Limitations and Future Improvements

The current project is a strong MVP with realtime booking and an implemented assistant flow, but several improvements are still possible:

- Add payment processing before final confirmation.
- Improve the assistant's language understanding and route ranking.
- Add better assistant support for changing dates, seats, or route options after a hold is created.
- Add automated tests for Supabase functions and the assistant API.
- Replace or remove the legacy Express scaffolding once the Python assistant API is the only backend path.
- Add admin screens for editing routes, vehicles, and seat layouts.
- Add richer notification delivery for reminders, hold expiration, and boarding updates.
- Add observability for assistant decisions, hold failures, confirmation errors, and check-in activity.

## 8. Conclusion

TransitFlow is a realtime transportation ticketing platform with both manual and conversational booking flows. It combines Vue, Pinia, Supabase Auth, Supabase Realtime, Postgres RPC functions, QR generation, QR scanning, and a Python assistant API into one cohesive project.

The strongest technical feature is the realtime seat tracking system. It handles temporary holds, expiration, date-specific confirmed bookings, multi-client updates, and database-level validation. The automated ticket-ordering assistant builds directly on this same system, allowing passengers to move from natural-language request to held seats and confirmed tickets while preserving the reliability of the manual booking flow.
