# TransitFlow Project Report

## 1. Project Overview

TransitFlow is a web-based transportation ticketing platform for searching routes, selecting seats, booking tickets, and managing passenger boarding. The application focuses on a realistic end-to-end ticket purchasing flow for rail and air-style transport services. It includes a customer-facing booking experience, authenticated user dashboards, QR-based tickets, and an admin operations console for monitoring ticket sales and check-ins.

The project is built as a modern single-page application with a Vue frontend, an Express backend layer, and Supabase as the main authentication, database, and realtime infrastructure. The current implementation already supports live route inventory, Supabase authentication, realtime seat status synchronization, temporary seat holds, ticket generation, QR check-in, and admin monitoring. A conversational automated ticket-ordering agent is also planned and partially prepared through the existing assistant chat interface and backend assistant route.

## 2. Main Functionality

### 2.1 User Authentication

TransitFlow uses Supabase Authentication with Google OAuth support. Users sign in through the authentication view, and the app exchanges OAuth callback codes for Supabase sessions. The authentication store keeps the current session, user object, and profile information synchronized across the app.

After authentication, the app creates or hydrates a profile record from Supabase. Profile data includes the user's email, first name, last name, avatar URL, and role. The role field is important because it separates normal passengers from administrators. The router uses this information to protect authenticated pages and admin-only routes.

Protected customer routes include:

- Dashboard
- Route search
- Seat selection
- Ticket view

Protected admin routes include:

- Admin dashboard
- Admin ticket operations

### 2.2 Route Search and Trip Discovery

The route search page lets passengers search transportation routes by departure city, destination, departure date, passenger count, transport type, vehicle type, and time of day. Route inventory is fetched from Supabase through the Pinia booking store.

Each route contains transport metadata such as:

- Transport type
- Departure location
- Destination
- Departure time
- Arrival time
- Vehicle code
- Vehicle type
- Vehicle capacity
- Seat layout metadata

The app also prevents users from selecting routes that have already departed for the selected date. This improves booking reliability because passengers cannot proceed into seat selection for an invalid departure time.

### 2.3 Realtime Seat Selection

The seat selection screen is one of the core features of TransitFlow. It displays an SVG-based interactive seat map for the selected vehicle and route. Seats are visually marked according to their current status:

- Available seats
- Temporarily held seats
- Confirmed booked seats
- Seats held by the current user

Passengers can click seats to hold or release them. A reservation timer shows how long the current hold remains valid. The default hold time is five minutes, with database-level protection that limits holds to a controlled duration.

The UI also displays a live booking summary, including selected seats, passenger information from the authenticated profile, selected travel date, route operator, departure and destination, and the current realtime hold count.

### 2.4 Booking Confirmation

When a passenger confirms the booking, TransitFlow calls a Supabase remote procedure named `confirm_booking`. This procedure validates that:

- The user is authenticated.
- The booking exists and belongs to the current user.
- The selected seats are still actively held.
- The holds have not expired.
- No other confirmed booking already owns the same seats for the same route and travel date.

If validation succeeds, the booking is marked as confirmed, the selected seat IDs are persisted on the booking, and a ticket record is created. The ticket's QR payload is set to the ticket ID so it can be scanned later by the admin check-in workflow.

After confirmation, temporary seat hold fields are cleared from the seats table. This is intentional: confirmed availability is derived from confirmed bookings for a specific travel date, while temporary holds are only used during checkout. This design avoids permanently locking a physical seat record across all travel dates.

### 2.5 Ticket Display and QR Code Generation

The ticket view loads a confirmed ticket from Supabase and enriches it with route, passenger, seat, and timeline information. The app generates QR assets on the client using the ticket payload.

Each ticket includes:

- Ticket ID
- Booking ID
- Passenger name and email
- Route details
- Travel date
- Departure and arrival time
- Seat codes
- Boarding status
- QR code data
- Timeline status such as valid, checked in, or expired

### 2.6 User Dashboard

The passenger dashboard summarizes upcoming trips, recent booking history, live stats, notifications, and ticket-related activity. Data is loaded from Supabase through the booking store.

The dashboard helps users see:

- Upcoming confirmed or held trips
- Recent booking history
- Notifications
- Live platform metrics
- Ticket status

### 2.7 Admin Operations Dashboard

The admin dashboard provides an operational overview for staff. It includes ticket metrics, seat fillness, checked-in passengers, expired tickets, and a passenger check-in feed.

Admins can select an operations date and view:

- Number of tickets sold for that date
- Number of tickets ready for check-in
- Number of checked-in passengers
- Number of expired tickets
- Seat fill percentage
- Passenger boarding feed

The dashboard subscribes to check-in table changes through Supabase Realtime, so boarding information refreshes when passengers are scanned.

### 2.8 Admin Ticket Operations and QR Check-In

The admin ticket operations page lets staff search and filter issued tickets. Tickets can be filtered by status, including valid, checked in, expired, and cancelled.

The page includes a camera-based QR scanner using the `html5-qrcode` library. When an admin scans a ticket QR code, the app calls the `check_in_ticket` Supabase procedure. This procedure:

- Requires admin privileges.
- Finds the ticket by QR payload or ticket ID.
- Rejects unknown tickets.
- Detects tickets that were already checked in.
- Blocks expired tickets when departure time has passed.
- Inserts a check-in record.
- Updates the ticket boarding status to `checked_in`.

This creates an atomic check-in flow, which means ticket validation and status update happen together at the database level.

## 3. Technical Components and Tools Used

### 3.1 Frontend

The frontend is built with Vue 3 and Vite. Vue provides the component-based UI structure, while Vite gives the project fast local development and production build tooling.

Major frontend technologies include:

- Vue 3 for the single-page application
- Vue Router for route navigation and route guards
- Pinia for global state management
- Bootstrap 5 for layout and base UI styling
- Custom CSS for TransitFlow's visual identity
- Axios for backend API calls
- Supabase JavaScript client for authentication, database queries, RPC calls, and realtime channels
- `qrcode` for client-side ticket QR asset generation
- `html5-qrcode` for camera-based QR scanning in the admin console

The frontend is organized into views, layouts, reusable components, stores, composables, services, and utilities. This separation keeps the app maintainable as the booking flow grows.

### 3.2 Backend

The backend is an Express application. It currently provides a structured API shell with route modules for health checks, authentication status, route search, bookings, dashboard data, and assistant messages.

Backend technologies include:

- Express for API routing
- CORS for frontend-backend integration
- Dotenv for environment configuration
- Node watch mode for backend development


### 3.3 Database and Realtime Layer

Supabase is the main backend platform for persistent data and realtime synchronization. The project includes a complete schema and incremental migrations.

Key database tables include:

- `profiles`
- `routes`
- `vehicles`
- `seats`
- `bookings`
- `tickets`
- `checkins`
- `notifications`

Supabase is also used for:

- Google OAuth authentication
- Row Level Security policies
- Role-based access control
- Postgres functions for transactional booking logic
- Realtime subscriptions for seat and check-in updates

Important stored procedures include:

- `release_expired_seat_holds`
- `hold_seat`
- `release_seat_hold`
- `release_booking_holds`
- `confirm_booking`
- `check_in_ticket`

### 3.4 State Management

Pinia stores manage application-wide state. The main stores are:

- `auth`: session, user, profile, OAuth flow, role checks
- `booking`: routes, selected route, seat map, active booking, ticket data, admin tickets, check-in feed, live stats
- `ui`: shared UI state

The booking store is the heart of the app. It coordinates route loading, seat map loading, realtime channel subscriptions, hold and release actions, booking confirmation, ticket fetching, admin metrics, and QR check-in.

### 3.5 Routing and Access Control

Vue Router defines the main application routes and enforces authentication requirements through route metadata. Routes can be marked as:

- Public
- Guest-only
- Authenticated-only
- Admin-only

Before each navigation, the router initializes the auth store if needed, redirects unauthenticated users to the login page, redirects signed-in users away from guest-only pages, and blocks non-admin users from admin screens.

## 4. Detailed Explanation of Realtime Seat Status Tracking

Realtime seat tracking is the most important technical feature in TransitFlow because ticketing platforms must prevent multiple passengers from selecting the same seat at the same time.

### 4.1 Seat Status Model

Each physical seat record belongs to a vehicle and has a status field. The supported statuses are:

- `available`: the seat can be selected.
- `held`: the seat is temporarily locked during checkout.
- `booked`: the seat is not available because it is part of a confirmed booking.

The `seats` table also stores temporary hold metadata:

- `held_by_booking_id`
- `held_by_user_id`
- `hold_expires_at`

This metadata lets the app know whether a held seat belongs to the current user, another passenger, or an expired hold that should be released.

### 4.2 Loading the Seat Map

When the user enters the seat selection page, the app loads the selected route, selected travel date, and vehicle. It then calls `fetchSeatMap`.

Before reading seats, the app calls `release_expired_seat_holds`. This clears stale holds from the database so users do not see seats as unavailable after another passenger abandoned checkout.

Then the app fetches all seats for the selected vehicle. It also separately fetches confirmed bookings for the same route and selected travel date. This second query is important because a physical vehicle seat can be reused on different dates. A seat should only be considered booked if it appears in a confirmed booking for the same route and same travel date.

The frontend combines these two sources:

- The `seats` table provides the physical layout and temporary hold state.
- The `bookings` table provides date-specific confirmed reservations.

This merged result becomes the visible seat map.

### 4.3 Holding a Seat

When a passenger clicks an available seat, the app calls the `hold_seat` Supabase function. This function uses database-level locking with `for update` to prevent race conditions. If two users try to hold the same seat at nearly the same time, the database handles the conflict consistently.

The function checks:

- The user is authenticated.
- The seat belongs to the selected route.
- The seat is not already booked for the selected travel date.
- The seat is not actively held by another passenger.
- Existing expired holds are released first.

If the seat can be held, the function either creates a new booking in `held` status or attaches the seat to the user's existing active held booking. It then updates the seat with the booking ID, user ID, and hold expiration timestamp.

### 4.4 Releasing a Seat

If the passenger clicks a seat they already hold, the app calls `release_seat_hold`. This clears the temporary hold fields from the seat and updates the related booking. If no seats remain in the booking, the booking returns to a draft state.

The app also releases holds when the user leaves the seat selection flow without confirming. The seat selection view listens for route changes and page hide events. If the user navigates away from the booking flow, the app calls `release_booking_holds` so seats become available for other passengers.

### 4.5 Reservation Timer

The frontend tracks the hold expiration timestamp returned by Supabase. A reservation countdown component displays the remaining time. If the timer expires, the app refreshes the seat map. Since `fetchSeatMap` calls `release_expired_seat_holds`, expired seats are cleaned up and shown as available again.

The database function also clamps hold duration to a controlled range, which helps prevent excessively long seat locks.

### 4.6 Supabase Realtime Synchronization

After loading a vehicle's seats, the booking store subscribes to a Supabase Realtime channel named for the active vehicle:

```text
seat-map:{vehicleId}
```

The subscription listens for Postgres changes on the `seats` table, filtered by the current `vehicle_id`. Whenever a seat is inserted, updated, or deleted for that vehicle, the frontend refreshes the seat map.

This means multiple connected users can see seat availability changes without manually refreshing the page. For example:

1. User A selects seat A1.
2. Supabase updates A1 to `held`.
3. Supabase Realtime broadcasts the change.
4. User B's browser receives the event.
5. User B's app reloads the seat map.
6. Seat A1 appears as held and cannot be selected by User B.

This realtime flow reduces double-booking risk and gives users confidence that the seat map reflects the current state of the system.

### 4.7 Confirmed Bookings and Date-Specific Availability

When a booking is confirmed, the selected seat IDs are stored on the confirmed booking record. The temporary hold fields on the seat records are then cleared.

This may look unusual at first, but it is a deliberate design choice. The `seats` table represents the physical seats on a vehicle, while `bookings` represents reservations for a route and travel date. If confirmed bookings permanently changed seat rows to `booked`, the same seat could become unavailable on every future travel date. By keeping confirmed booking ownership in the `bookings` table, the app can correctly show a seat as booked only for the relevant travel date.

This approach supports future expansion to recurring routes, daily schedules, and multiple departures using the same vehicle layout.

### 4.8 Failure Handling

The seat system includes several safeguards:

- Expired holds are released before seat reads and booking operations.
- Database functions validate ownership before releasing or confirming holds.
- Confirm booking checks for conflicts against other confirmed bookings.
- Realtime updates keep connected clients synchronized.
- The frontend displays seat map errors when a hold or release fails.
- Navigation cleanup prevents abandoned holds from lasting until timeout.

Together, these safeguards make the seat tracking flow reliable even when multiple passengers interact with the same route at the same time.

## 5. Automated Agent for Ticket Ordering

TransitFlow includes the foundation for an automated ticket-ordering assistant. The current UI already has an assistant chat window that lets passengers ask about destinations, schedules, and booking help. The frontend sends messages and conversation history to a backend assistant route.

The assistant endpoint is currently a prepared integration point rather than a fully autonomous booking agent. It accepts chat messages and returns an acknowledgement, which means the frontend and backend plumbing are already in place. The next implementation step is to connect this endpoint to an automated agent capable of understanding passenger intent and guiding the user through the booking process.

The planned automated ticket-ordering agent will be able to:

- Understand natural-language trip requests such as "Book me a morning train from Hanoi to Da Nang tomorrow."
- Search available routes based on departure, destination, time, date, and passenger count.
- Compare route options using departure time, arrival time, vehicle type, and availability.
- Recommend the best trip based on user preferences.
- Help select available seats from realtime seat inventory.
- Start or continue a temporary seat hold.
- Guide the passenger through confirmation.
- Explain booking errors such as expired holds, sold-out routes, or unavailable seats.

This feature is especially valuable because ticket booking can involve several steps and constraints. Instead of forcing passengers to manually adjust filters and inspect every route, the agent can act as a conversational layer over the existing booking system.

The agent will rely on the existing architecture rather than replacing it. It should call the same route, seat, hold, and confirmation workflows that the visual UI already uses. This keeps the automated flow consistent with the manual booking flow and avoids creating two separate sources of truth.

## 6. Innovative Features and Unique Approaches

### 6.1 Realtime Seat Holds with Database-Level Safety

The project does not rely only on frontend state to mark seats as selected. Seat holds are written to Supabase through transactional Postgres functions. This is a stronger design because the database becomes the authority for seat availability.

The use of `for update`, ownership checks, expiration timestamps, and conflict detection makes the seat selection process much closer to a real ticketing system.

### 6.2 Date-Specific Booking Logic

The app separates physical seat records from date-specific confirmed bookings. This is a unique and important design decision. It allows the same vehicle and same seat layout to be reused across multiple travel dates without corrupting availability for future departures.

### 6.3 Realtime Admin Boarding Feed

Admin users can monitor passenger check-ins as they happen. The admin dashboard subscribes to check-in changes and refreshes the passenger feed and ticket data when scans occur.

This gives the admin side a live operations feel rather than a static reporting dashboard.

### 6.4 QR-Based Ticket Lifecycle

TransitFlow includes a full ticket lifecycle:

1. Confirm a booking.
2. Generate a ticket.
3. Create a QR payload.
4. Display the QR code to the passenger.
5. Scan the QR code from the admin console.
6. Validate ticket status and expiration.
7. Mark the passenger as checked in.

This bridges the digital booking experience with a real-world boarding workflow.

### 6.5 Agent-Ready Architecture

The assistant chat window and backend assistant route make the app ready for an automated ticket-ordering agent. The project already has clear booking actions and state transitions, which means the future agent can be implemented as an orchestration layer over existing functions instead of as a separate system.

## 7. Challenges Encountered and How They Were Addressed

### 7.1 Preventing Double Booking

One of the biggest challenges in a ticketing system is preventing two passengers from booking the same seat. This was addressed by moving critical seat operations into Supabase stored procedures. The `hold_seat` and `confirm_booking` functions validate seat status directly in the database and use row locking to reduce race conditions.

### 7.2 Handling Abandoned Seat Holds

Users may close the browser, navigate away, or abandon checkout after selecting seats. Without cleanup, this would make seats appear unavailable forever. The project addresses this with expiration timestamps and the `release_expired_seat_holds` function. The frontend also releases active booking holds when the user leaves the seat selection flow.

### 7.3 Supporting Reusable Vehicle Layouts Across Dates

A naive implementation might mark a seat row as permanently booked after confirmation. That would break future departures using the same vehicle layout. TransitFlow solves this by storing confirmed seat ownership on date-specific booking records and using the seats table mainly for physical layout and temporary holds.

### 7.4 Keeping Multiple Clients in Sync

Realtime seat selection requires all connected users to see updates quickly. Supabase Realtime channels were used to listen for seat changes filtered by vehicle. When an event arrives, the app refreshes the seat map, ensuring users see the latest status.

### 7.5 Role-Based Admin Features

The admin console needs access to operational data that regular passengers should not manage. This was addressed with profile roles, route guards, Supabase Row Level Security policies, and admin-only database functions such as `check_in_ticket`.

### 7.6 Integrating QR Scanning with Ticket Validation

QR scanning introduces browser permission issues, duplicate scans, expired tickets, and unknown ticket payloads. The project handles these cases in both the UI and the database function. The scanner component manages camera states such as idle, starting, running, denied, unsupported, and error. The database function returns clear result statuses such as checked in, already checked in, expired, and not found.

## 8. Current Limitations and Future Improvements

The project is already functional as a strong MVP, but several improvements are planned:

- Implement the automated ticket-ordering agent using the prepared assistant route.
- Connect remaining mock backend endpoints fully to Supabase.
- Add payment processing before final ticket confirmation.
- Add richer notification delivery for booking updates and boarding reminders.
- Expand seat layouts for different transport types and vehicle configurations.
- Add admin tools for creating and editing routes, vehicles, and seat maps.
- Add automated tests for Supabase functions and frontend booking flows.
- Improve observability for booking errors, expired holds, and check-in activity.

## 9. Conclusion

TransitFlow demonstrates a complete transportation ticketing workflow with a strong focus on realtime seat availability and operational reliability. The application combines Vue, Pinia, Express, Supabase Auth, Supabase Realtime, Postgres functions, QR code generation, and camera-based scanning into a cohesive booking platform.

The most technically significant part of the project is the realtime seat tracking system. It handles temporary holds, expiration, ownership, date-specific confirmed bookings, and multi-client synchronization. This makes the app behave much more like a real production ticketing platform than a simple static reservation demo.

The upcoming automated ticket-ordering agent will build on this foundation by turning the existing booking workflow into a guided conversational experience. Because the system already has well-defined route search, seat selection, hold, confirmation, and ticket functions, the agent can become a natural extension of the platform rather than a separate feature.
