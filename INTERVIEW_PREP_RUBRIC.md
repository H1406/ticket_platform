# TransitFlow 1-on-1 Interview Preparation

Use this as your speaking guide during the interview. The goal is to connect every rubric item to the exact implementation in this codebase, then answer follow-up questions with confidence.

## 0. Opening Summary

**30-second answer**

TransitFlow is a Vue 3 and Vite ticket-booking platform for transport routes. It supports authentication, route search, realtime seat selection, booking confirmation, QR ticket generation, and an admin QR check-in workflow. I used Vue Router for protected pages, Pinia for shared state, Supabase for auth/database/RPC/realtime, and reusable Vue components for the interface.

**Files to open first**

- `package.json`
- `src/main.js`
- `src/router/index.js`
- `src/stores/auth.js`
- `src/stores/booking.js`
- `src/views/SearchRoutesView.vue`
- `src/views/SeatSelectionView.vue`
- `src/views/TicketView.vue`
- `src/views/AdminTicketsView.vue`
- `supabase/migrations/010_realtime_seat_reservations.sql`
- `supabase/migrations/012_ticket_checkin.sql`

**Best demo route**

1. Start at `/`.
2. Sign in through `/auth`.
3. Search routes at `/search`.
4. Choose a route and seat at `/seat-selection`.
5. Confirm booking and land on `/ticket?ticketId=...`.
6. As admin, open `/admin/tickets` and demonstrate filtering, pagination, and QR check-in.

## 1. Stage 1: Project Setup and Structure

### What the rubric asks

- Create a Vite or Vue CLI project.
- Add Vue Router.
- Create simple pages such as Home, News, and About.

### How this project satisfies it

This project uses Vite and Vue 3. The Vite setup is visible in `package.json`, with `vite`, `@vitejs/plugin-vue`, and scripts such as `npm run dev` and `npm run build`.

Vue is bootstrapped in `src/main.js`. The app imports `createApp`, creates Pinia with `createPinia()`, installs Pinia and the router, then mounts the root app to `#app`.

Routing is defined in `src/router/index.js`. Instead of simple starter pages named `Home.vue`, `News.vue`, and `About.vue`, the project has domain-specific views:

- `LandingView.vue` as the home/landing page.
- `SearchRoutesView.vue` as the searchable content page.
- `AuthView.vue`, `DashboardView.vue`, `SeatSelectionView.vue`, and `TicketView.vue` for passenger workflows.
- `AdminDashboardView.vue` and `AdminTicketsView.vue` for admin workflows.
- `NotFoundView.vue` for unknown routes.

The important explanation is that the project moved beyond the starter page names into a realistic ticketing application structure.

### Exact code to mention

- `src/main.js`: installs Pinia and Vue Router.
- `src/router/index.js`: defines page routes and route metadata.
- `src/router/index.js`: uses lazy-loaded components with `() => import(...)`.
- `src/router/index.js`: route guards protect passenger and admin pages.

### Likely questions

**Q: How do you know this is a Vite project?**

A: `package.json` has `vite` scripts and the Vite Vue plugin. The scripts include `dev`, `build`, and `preview`, which are Vite conventions.

**Q: Where is Vue Router configured?**

A: In `src/router/index.js`. It imports `createRouter` and `createWebHistory`, defines the route array, and exports the router for `src/main.js` to install.

**Q: Why are there no `Home.vue`, `News.vue`, and `About.vue` files?**

A: I adapted the starter requirement into the actual app domain. `LandingView.vue` is the home page, `SearchRoutesView.vue` provides searchable content, and authentication/profile/user flows replaced the simple About input demo. I would explain this clearly rather than pretending those exact filenames exist.

**Q: What is the purpose of route meta fields?**

A: They describe route behavior. For example, `requiresAuth` blocks unauthenticated users, `guestOnly` redirects signed-in users away from the auth page, and `requiresAdmin` protects admin pages.

## 2. Stage 1: Home/About/Responsiveness

### What the rubric asks

- Home page with title, paragraph, and images.
- About page with inputs and conditional image based on radio selection.
- Responsive layout across multiple devices.

### How this project maps to the requirement

The app's landing page is `src/views/LandingView.vue`. It has a main title, descriptive paragraph, metrics, feature cards, and a responsive Bootstrap grid. It is more application-specific than a basic home page.

The app does not contain a literal `AboutView.vue` with first-name/last-name fields and radio-image selection. Instead, form and reactivity requirements appear in real workflows:

- `src/views/AuthView.vue` has email/password inputs with validation.
- `src/views/SearchRoutesView.vue` has route search inputs for departure, destination, date, and passenger count.
- `src/components/search/SearchFilters.vue` has filter controls using `v-model`.
- `src/views/SeatSelectionView.vue` displays user profile information from the authenticated user.

Responsiveness is handled primarily with Bootstrap classes and custom CSS:

- Bootstrap grid classes such as `row`, `col-lg-*`, `col-md-*`, `col-xl-*`.
- `.table-responsive` in admin ticket tables.
- `@media (max-width: 991px)` in `src/assets/main.css`.
- `min-width: 320px` in global body styling.

### Exact code to mention

- `src/views/LandingView.vue`: hero title, paragraph, feature cards, metrics.
- `src/views/AuthView.vue`: `form.email`, `form.password`, `validationError`, and `@submit.prevent`.
- `src/views/SearchRoutesView.vue`: `reactive` form, `v-model`, date validation with `:min`.
- `src/assets/main.css`: global design variables and responsive layout adjustment.

### Likely questions

**Q: How did you make the app responsive?**

A: I used Bootstrap's mobile-first grid and responsive column classes. For example, the search page changes from stacked mobile inputs to multi-column desktop layout with `col-md-6` and `col-lg-3`. For admin tables, I used `.table-responsive` so wide tabular data remains usable on smaller screens.

**Q: Where do you use form validation?**

A: In `src/views/AuthView.vue`, `validationError` is a computed property that checks whether email and password are present before allowing submission. In `src/views/SearchRoutesView.vue`, the date input uses `required` and `:min="todayInputValue"` so users cannot select dates before today.

**Q: How would you add the original About page requirement if asked?**

A: I would add an `AboutView.vue`, register it in `src/router/index.js`, use two `v-model` fields for first name and last name, a computed welcome message, radio buttons for image choice, and a `v-if` or dynamic `:src` image binding.

## 3. Stage 1: News Page Equivalent

### What the rubric asks

- Display a list from a local JSON file.
- At least four fields per item.
- Search by date, title/content/category.
- Enough items for pagination.

### How this project maps to it

This project does not implement a literal news page from a local JSON file. Instead, the equivalent dynamic list features are implemented with real ticket and route data from Supabase:

- `SearchRoutesView.vue` displays searchable route results.
- `TicketView.vue` displays paginated tickets.
- `AdminTicketsView.vue` displays searchable, filterable, paginated ticket operations data.

This is stronger than the basic local JSON requirement because the data comes from persisted Supabase tables and joins.

### Exact code to mention

- `src/views/SearchRoutesView.vue`: `filteredRoutes` searches departure, destination, vehicle type, transport type, and departure time.
- `src/views/TicketView.vue`: `currentPage`, `ticketsPerPage`, `totalPages`, `paginatedTickets`, and pagination controls.
- `src/views/AdminTicketsView.vue`: `searchTerm`, `statusFilter`, `filteredTickets`, `paginatedTickets`.
- `src/stores/booking.js`: `fetchRoutes`, `fetchUserTickets`, and `fetchAdminTickets` load real data.

### Likely questions

**Q: Where is your search functionality?**

A: Search is in `src/views/SearchRoutesView.vue` for route discovery and in `src/views/AdminTicketsView.vue` for admin ticket search. The search page filters by departure, destination, transport type, vehicle type, and time of day. The admin page filters by ticket ID, passenger, route, and status.

**Q: Where is pagination implemented?**

A: `src/views/TicketView.vue` paginates user tickets five per page. `src/views/AdminTicketsView.vue` also paginates admin tickets five per page using computed `totalPages`, `pageStartIndex`, and `paginatedTickets`.

**Q: Why use Supabase instead of local JSON?**

A: The rubric allowed external sources/APIs in later stages. Supabase makes the application more realistic because tickets, routes, bookings, and check-ins are persisted instead of being static demo records.

## 4. Stage 2: Technical Requirements

### Vue components and modular structure

The project separates full pages, layouts, reusable components, stores, services, composables, and utilities.

Examples:

- Views: `src/views/SearchRoutesView.vue`, `src/views/SeatSelectionView.vue`, `src/views/TicketView.vue`.
- Layouts: `src/layouts/MainLayout.vue`, `src/layouts/AdminLayout.vue`, `src/layouts/AuthLayout.vue`.
- Components: `SearchFilters.vue`, `SearchResultCard.vue`, `InteractiveSeatMap.vue`, `TicketCard.vue`, `QrScannerPanel.vue`.
- Stores: `src/stores/auth.js`, `src/stores/booking.js`.
- Composable: `src/composables/useReservationCountdown.js`.
- Utilities: `src/utils/ticketQr.js`, `src/utils/ticketTimeline.js`.

### Vue directives

Be ready to point out these examples:

- `v-model`: form fields in `AuthView.vue`, `SearchRoutesView.vue`, `SearchFilters.vue`, and `AdminTicketsView.vue`.
- `v-if` / `v-else-if` / `v-else`: loading, error, empty, and success states in `TicketView.vue`, `SeatSelectionView.vue`, and `QrScannerPanel.vue`.
- `v-for`: route cards, ticket list items, pagination buttons, seat SVG elements, and admin table rows.
- `v-bind` shorthand `:`: dynamic props such as `:route`, `:seats`, `:disabled`, `:class`, `:aria-current`, `:viewBox`.
- `v-on` shorthand `@`: click handlers, submit handlers, and emitted component events.

### Arrays and dynamic data

The strongest examples are in `src/stores/booking.js`:

- `routes`, `seatMap`, `tickets`, `adminTickets`, `notifications`, and `passengerTable` are arrays in Pinia state.
- `filteredRoutes` and `filteredTickets` use array filtering.
- `paginatedTickets` uses `slice`.
- `mapTicketRows` maps joined Supabase rows into UI-friendly ticket objects.
- `bookedSeatIds` uses `Set` to identify seats already confirmed for a route/date.

### Methods and computed properties

Examples:

- `SearchRoutesView.vue`: `filteredRoutes`, `todayInputValue`, `hasRouteDeparted`, `selectRoute`.
- `SeatSelectionView.vue`: `selectedSummary`, `activeRoute`, `canContinue`, `travelDateLabel`, `continueToTicket`.
- `TicketView.vue`: `selectedTicket`, `totalPages`, `paginatedTickets`, `paginationSummary`.
- `AdminTicketsView.vue`: `filteredTickets`, `totalPages`, `paginatedTickets`.
- `booking.js`: getters `selectedSeats`, `selectedSeatCodes`, and `selectedSeatCount`.

### External sources and APIs

The main external source is Supabase:

- Auth through `supabase.auth`.
- Database reads through `.from(...).select(...)`.
- Transactional logic through `supabase.rpc(...)`.
- Realtime updates through `supabase.channel(...).on('postgres_changes', ...)`.

There is also an assistant API client in `src/services/api.js` that posts to `/assistant`, and QR libraries:

- `qrcode` in `src/utils/ticketQr.js`.
- `html5-qrcode` in `src/components/admin/QrScannerPanel.vue`.

### Accessibility

Useful talking points:

- Form inputs use visible `<label>` elements.
- Buttons have disabled states for invalid actions.
- Ticket pagination has `aria-label` and active page uses `aria-current`.
- Admin data is shown in a real HTML `<table>`, not only divs.
- The QR scanner reports denied, unsupported, and error states as visible text.

### Likely questions

**Q: Why use Pinia?**

A: Pinia centralizes app-wide state like routes, selected seats, tickets, admin tickets, and loading/error states. Without it, the booking flow would need too much prop drilling between search, seat selection, ticket, and admin pages.

**Q: What is an example of a computed property and why use it?**

A: `filteredRoutes` in `SearchRoutesView.vue` recomputes route results whenever search form or filter values change. It keeps filtering declarative and avoids manually updating a separate list.

**Q: What is an example of a reusable component?**

A: `InteractiveSeatMap.vue` only receives `seats` and emits `toggle-seat`. It does not know how Supabase works. That keeps UI rendering separate from booking/business logic in the Pinia store.

## 5. Stage 2: Functional Requirements

### Registration and login

Implemented through Supabase Auth in `src/stores/auth.js`.

- `initialize()` loads the current session.
- `signInWithPassword()` handles email/password login.
- `signUp()` handles registration.
- `signInWithGoogle()` handles OAuth.
- `applySession()` hydrates the user and profile.

`src/router/index.js` then uses `requiresAuth`, `guestOnly`, and `requiresAdmin` to decide page access.

### Differentiated authenticated and unauthenticated visibility

Unauthenticated users can see the landing page and auth page. Authenticated users can access dashboard, search, seat selection, and tickets. Admin users can access `/admin` and `/admin/tickets`.

### Search and filters

Implemented in:

- `SearchRoutesView.vue` for passenger route search.
- `SearchFilters.vue` for vehicle/type/time filters.
- `AdminTicketsView.vue` for admin ticket search and status filters.

### Social features: liking or voting

The app does not currently implement liking or voting. The closest user action feature is seat selection and ticket check-in. If asked, be honest: social liking/voting is not part of the ticketing domain yet. A domain-appropriate future version could allow passengers to rate routes or vote for preferred departure times.

### Create, edit, delete content

In this app, authorized actions are implemented as booking operations rather than generic CRUD:

- Users create temporary bookings by holding seats through `hold_seat`.
- Users can release/cancel active booking holds through `release_booking_holds`.
- Users confirm a booking through `confirm_booking`.
- Admins update ticket state through `check_in_ticket`.

These actions are backed by Supabase RPC functions, which is safer than letting the client directly mutate critical ticket state.

### Persistent data storage

Supabase is the persistent store. The schema and migrations live in `supabase/migrations`. Important tables include:

- `profiles`
- `routes`
- `vehicles`
- `seats`
- `bookings`
- `tickets`
- `checkins`
- `notifications`

### Likely questions

**Q: How do you prevent unauthenticated users from booking?**

A: The router blocks protected routes through `requiresAuth`. The Supabase RPC functions also check `auth.uid()`, so the database layer rejects unauthenticated booking actions even if someone bypasses the UI.

**Q: How do you differentiate admin and user content?**

A: The profile role is normalized in `src/stores/auth.js` as `isAdmin`. The router checks `to.meta.requiresAdmin` and redirects non-admin users to the dashboard.

**Q: What data is persistent?**

A: Routes, vehicles, seats, bookings, tickets, check-ins, notifications, and profiles are persistent Supabase records.

## 6. Stage 2: Report and Code

### What to say

The report is in `PROJECT_REPORT.md`. It describes the main functionality, technical tools, advanced features, and challenges. The best way to present it is:

1. Main function: booking transport tickets with realtime seat status and QR boarding.
2. Technical components: Vue 3, Vite, Vue Router, Pinia, Bootstrap, Supabase, QR libraries, Python assistant API.
3. Innovative features: realtime seat holds, transactional booking RPCs, admin QR scanner, ticket timeline status, assistant booking API.
4. Challenges: preventing double booking, managing expired holds, keeping UI state synchronized with database state, and handling role-based access.

### Likely questions

**Q: What was the hardest challenge?**

A: Preventing double booking was the hardest. I solved it by moving seat hold and confirm logic into Supabase RPC functions that can lock/check database state transactionally, instead of relying only on frontend checks.

**Q: What are you most proud of?**

A: The realtime seat selection flow, because the UI shows a friendly seat map but the underlying logic handles held seats, confirmed seats, expiry, current-user holds, and Supabase realtime refreshes.

## 7. Stage 3: Technique Complexity and Relevance

### Best advanced technique to present

Present **realtime seat reservation with transactional Supabase RPCs** as the advanced Vue-related technique.

This is relevant because ticket booking depends on accurate seat availability. A basic app might just store selected seats locally. This app coordinates frontend Vue state, Supabase realtime events, and database functions to reduce double-booking risk.

### How the technique works

Frontend flow:

1. `SearchRoutesView.vue` lets the user choose route and date.
2. `SeatSelectionView.vue` loads seat data and subscribes to realtime updates.
3. `InteractiveSeatMap.vue` renders seats from props and emits the selected seat ID.
4. `bookingStore.toggleSeat()` decides whether to call `hold_seat` or `release_seat_hold`.
5. `fetchSeatMap()` reloads current seat status and merges confirmed booking seats for the selected route/date.
6. `subscribeToSeatUpdates()` listens for Supabase realtime changes on the `seats` table.
7. `useReservationCountdown()` displays the hold timer.
8. `confirmBooking()` calls `confirm_booking` to turn the hold into a persisted ticket.

Database flow:

1. `hold_seat` checks the authenticated user.
2. It calls `release_expired_seat_holds`.
3. It selects the seat `for update`.
4. It rejects seats already confirmed for the same route and travel date.
5. It rejects seats currently held by another passenger.
6. It creates or updates a held booking.
7. It updates the seat hold metadata and expiry.

### Exact code to mention

- `src/views/SeatSelectionView.vue`: loads seat selection, subscribes to updates, handles cleanup.
- `src/components/seatmap/InteractiveSeatMap.vue`: SVG dynamic seat rendering.
- `src/stores/booking.js`: `fetchSeatMap`, `subscribeToSeatUpdates`, `toggleSeat`, `confirmBooking`.
- `src/composables/useReservationCountdown.js`: live timer.
- `supabase/migrations/010_realtime_seat_reservations.sql`: database functions and realtime publication.

### Likely questions

**Q: Why is this more advanced than basic Vue?**

A: It combines Vue reactivity, global state, component events, realtime subscriptions, and backend transaction logic. The UI updates reactively, but the real seat ownership rules are enforced in the database.

**Q: What happens if two users click the same seat?**

A: The database function selects and validates the seat in a controlled transaction. If the seat is already held by another user and the hold has not expired, it raises an error. The frontend then shows the current seat state after re-fetching.

**Q: Why use a timer?**

A: Seat holds should not last forever. The timer makes the temporary hold visible to the user, and `release_expired_seat_holds` cleans up expired holds in the database.

## 8. Stage 3: Implementation Quality

### Strong features to emphasize

**Realtime seat map**

- Data-driven SVG layout.
- Seat states: available, held, booked, held by current user.
- Realtime subscription refreshes seat map.
- Holds expire and can be cancelled.

**Ticket QR generation**

- `src/utils/ticketQr.js` generates PNG data URLs and SVG from ticket payload.
- `TicketView.vue` lets users download the QR code.

**Admin QR check-in**

- `QrScannerPanel.vue` uses `html5-qrcode`.
- `bookingStore.checkInTicketFromQr()` calls the Supabase `check_in_ticket` RPC.
- `check_in_ticket` validates admin privileges, ticket existence, duplicate check-in, and expiry.

**Ticket timeline**

- `src/utils/ticketTimeline.js` calculates valid, checked-in, and expired ticket states.
- This logic is reused when mapping ticket rows for user and admin views.

### Likely questions

**Q: How does QR check-in work end to end?**

A: A confirmed ticket has a QR payload. The user sees the QR in `TicketView.vue`. Admin opens `AdminTicketsView.vue`, starts `QrScannerPanel.vue`, and scans it. The decoded payload is passed to `bookingStore.checkInTicketFromQr()`, which calls `check_in_ticket` in Supabase. The function validates role, finds the ticket, prevents duplicates and expired check-ins, inserts a check-in row, and updates boarding status.

**Q: What error states do you handle?**

A: Loading errors for routes, seats, tickets, and admin tickets. QR scanner states for denied camera permission, unsupported camera, generic scanner error, empty QR payload, ticket not found, already checked in, expired, and successful check-in.

**Q: Why use RPC functions instead of direct frontend updates?**

A: Seat holds and check-ins are business-critical. RPC functions let the database enforce rules atomically and consistently, so the frontend cannot accidentally create invalid bookings.

## 9. Stage 3: Video Content and Live Coding Preparation

### Best live-coding option

Use a small, safe change in `InteractiveSeatMap.vue` or `TicketView.vue`. Avoid live-coding database migrations during the interview because they are harder to recover from if something goes wrong.

### Live coding option A: improve seat accessibility

Add keyboard accessibility to seats:

- Add `tabindex="0"` to the seat `<g>` or move clickable behavior to a button-like element if refactoring.
- Add `role="button"`.
- Add `:aria-label="\`Seat ${seat.code}, ${seat.status}\`"`.
- Add `@keydown.enter="emit('toggle-seat', seat.id)"`.
- Add `@keydown.space.prevent="emit('toggle-seat', seat.id)"`.

What to say:

I am improving accessibility so users who cannot use a mouse can still select a seat. The component is already data-driven, so I only need to add semantic attributes and keyboard events to the repeated seat element.

### Live coding option B: add an admin filter option

Add a status option such as "Ready for check-in" in `AdminTicketsView.vue`:

- Add an `<option value="ready">Ready for check-in</option>`.
- Add a condition in `matchesStatus`: `statusFilter.value === 'ready' && ticket.canCheckIn`.

What to say:

I am extending the existing computed filter rather than rewriting the table. This shows how the architecture supports small feature changes with low risk.

### Live coding option C: adjust tickets per page

Change `ticketsPerPage` from `5` to a constant based on screen or a selected value. This is easy but less impressive than A or B.

## 10. Fast Rubric-to-Code Matrix

| Rubric item | Best evidence in code |
|---|---|
| Vite setup | `package.json`, `src/main.js` |
| Vue Router | `src/router/index.js` |
| Multiple components/views | `src/views/*`, `src/components/*`, `src/layouts/*` |
| Home page | `src/views/LandingView.vue` |
| Forms | `src/views/AuthView.vue`, `src/views/SearchRoutesView.vue` |
| Search | `src/views/SearchRoutesView.vue`, `src/views/AdminTicketsView.vue` |
| Pagination | `src/views/TicketView.vue`, `src/views/AdminTicketsView.vue` |
| Arrays | `src/stores/booking.js` state and mapping methods |
| `v-model` | Auth, search, filters, admin tickets |
| `v-if` | Loading/error/empty states |
| `v-for` | Routes, tickets, seats, pagination buttons |
| `v-bind` | Dynamic props, classes, disabled states, SVG attributes |
| `v-on` | Clicks, submits, emitted events |
| Validation | Auth validation, date min/required, booking guards |
| Accessibility | Labels, tables, responsive tables, `aria-current`, `aria-label` on pagination |
| Auth | `src/stores/auth.js`, `src/router/index.js` |
| Role-based access | `requiresAdmin`, `profile.isAdmin` |
| Persistent storage | `supabase/migrations/*`, Supabase calls in `booking.js` |
| External API/source | Supabase, assistant API, QR libraries |
| Advanced technique | Realtime seat holds and QR check-in |

## 11. Hard Questions and Safe Answers

**Q: What is currently incomplete against the original rubric?**

A: The exact starter pages `Home.vue`, `News.vue`, and `About.vue` are not present under those names, and there is no social like/vote feature. I focused the project on a realistic ticketing platform with route search, booking, QR tickets, admin check-in, and Supabase persistence. If required, I could add the missing starter pages or a route-rating feature quickly.

**Q: What would you improve next?**

A: I would add automated tests for the route filtering, ticket timeline utility, and booking store actions. I would also improve accessibility on the SVG seat map and add route ratings as a domain-specific version of the social feature requirement.

**Q: What is the biggest technical risk?**

A: Realtime consistency. The frontend listens to seat changes, but final correctness must be enforced by the database. That is why seat holding, release, confirmation, and check-in are implemented through Supabase RPC functions.

**Q: How do you handle expired tickets?**

A: `ticketTimeline.js` calculates whether the departure date/time has passed. The admin check-in RPC also blocks expired tickets at the database level.

**Q: What coding conventions did you follow?**

A: Vue single-file components use `<script setup>`, camelCase variable names, PascalCase component names, focused reusable components, Pinia stores for global state, and utility files for shared logic like QR generation and ticket timeline status.

## 12. Final Closing Answer

If asked to summarize the project at the end:

TransitFlow started from the required Vue concepts but became a realistic ticketing platform. The core Vue skills are visible in routing, components, directives, forms, computed properties, pagination, and responsive layouts. The advanced part is realtime seat booking with Supabase RPCs and admin QR check-in. I designed it so the frontend is reactive and modular, while critical booking rules are enforced persistently in the database.
