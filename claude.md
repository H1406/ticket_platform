# Prompt: Implement Ticket Visualization and Admin QR Check-In

You are working in the `ticket_platform` Vue/Vite application. Implement a ticket visualization experience for users and an admin ticket operations page with QR camera scanning, check-in, and expiry handling.

## Current Project Context

- Frontend stack: Vue 3, Vite, Pinia, Vue Router, Bootstrap-style utility classes, Supabase client.
- Existing user ticket page: `src/views/TicketView.vue`.
- Existing ticket card component: `src/components/ticket/TicketCard.vue`.
- Existing admin page: `src/views/AdminDashboardView.vue`.
- Existing routes: `src/router/index.js`.
- Existing booking store: `src/stores/booking.js`.
- Existing QR utility: `src/utils/ticketQr.js`.
- Existing Supabase tables/migrations include `tickets`, `bookings`, `routes`, `seats`, and `checkins`.

## Goal

Build a complete ticket viewing and validation workflow:

1. Users can see a list of all purchased tickets.
2. Users can click a ticket to view specific ticket details.
3. Admins can see all available tickets.
4. Admins can use the device camera to scan a QR code on a ticket.
5. A successful scan checks the ticket in.
6. The system detects expired tickets when the current date/time is past the ticket travel date/time.

## User Ticket Page Requirements

Update the existing ticket experience so `/ticket` is not only a single latest-ticket view.

### Ticket List

- Fetch all tickets purchased by the authenticated user.
- Show the tickets in a clear, scannable list.
- Each list item should include:
  - Route name, such as `departure to destination`.
  - Passenger name.
  - Seat code or seat summary.
  - Departure date and time.
  - Ticket status.
  - Check-in status.
  - Expiry state.
- The list should support empty, loading, and error states.
- If the user has no purchased tickets, show a useful empty state that sends them toward booking/search.

### Ticket Details

- Let the user click a ticket in the list.
- Show the selected ticket details beside or below the list depending on viewport size.
- Include:
  - Ticket ID.
  - Booking ID.
  - Passenger name and email.
  - Route details.
  - Operator/vehicle if available.
  - Seat details.
  - Departure date/time and arrival time.
  - Ticket QR code.
  - Current status.
  - Check-in timestamp if checked in.
  - Expired indicator if expired.
- Preserve support for direct links like `/ticket?ticketId=<id>` by preselecting that ticket.
- Keep the QR download action for the selected ticket.

## Admin Page Requirements

Add or extend an admin page for ticket operations. It can be part of `/admin` or a dedicated child page such as `/admin/tickets` if that better fits the existing router/layout.

### All Tickets Table

- Admins should see all available tickets, not only the current user's tickets.
- Include columns for:
  - Ticket ID.
  - Passenger.
  - Route.
  - Seat.
  - Departure date/time.
  - Boarding/check-in status.
  - Expiry status.
  - Last check-in timestamp.
- Add basic filtering/search:
  - Search by ticket ID, passenger name, or route.
  - Filter by status: all, valid, checked in, expired, cancelled if supported.
- Add loading, empty, and error states.

### Camera QR Scanner

- Add a camera scanner panel for admins.
- Request camera access only when the admin clicks a clear "Start scanner" control.
- Show clear camera permission, denied, unsupported browser, and scanner error states.
- Use a maintained browser QR scanning library if already available, or add one appropriate for Vue/Vite such as `html5-qrcode` or `qr-scanner`.
- When a QR code is scanned:
  - Parse the scanned value as the ticket QR payload.
  - Look up the matching ticket by `tickets.qr_payload` or ticket `id`.
  - Validate the ticket before check-in.
  - If valid and not already checked in, insert a row into `checkins`.
  - Update `tickets.boarding_status` to `checked_in`.
  - Show a success result with ticket and passenger details.
  - Refresh the admin tickets table.
- Prevent duplicate check-ins:
  - If a ticket already has a check-in record or `boarding_status` is `checked_in`, show an "already checked in" result instead of inserting another check-in.
- Stop the camera stream when:
  - The admin clicks "Stop scanner".
  - The admin navigates away.
  - The component unmounts.

## Ticket Expiry Rules

Implement a single shared helper for ticket timeline status instead of scattering date comparisons throughout components.

### Expected Behavior

- A ticket is expired when the current date/time is later than the ticket departure date/time.
- If the available schema only has route `departure_time` but no travel date, use the best available booking/ticket timestamp and clearly name the limitation in code comments.
- If a travel date exists or should be added, prefer an explicit field such as `travel_date` or `departure_at`.
- Expired tickets:
  - Should be visually labeled as expired.
  - Should not be eligible for check-in.
  - Should show a clear failed scan result in the admin scanner.
- Checked-in tickets should remain checked in even after travel time passes, but the UI may also show that the trip has passed.

## Data Access Expectations

Prefer Supabase queries through existing services/stores unless the project pattern clearly favors backend API routes.

### Suggested Store/API Work

Extend `src/stores/booking.js` or create a focused ticket/admin store if cleaner.

Add actions similar to:

- `fetchUserTickets()`
- `fetchTicket(ticketId)`
- `fetchAdminTickets()`
- `checkInTicketFromQr(qrPayload)`
- `refreshTicketStatuses()` or a helper used while mapping rows

Ticket queries should join the related records needed for display:

- `tickets`
- `bookings`
- `routes`
- `seats` where possible
- `profiles` or authenticated user metadata for passenger details
- `checkins`

If Supabase relationship nesting is awkward for `seat_ids uuid[]`, map available seat codes defensively and avoid crashing when seat data is missing.

## Security and RLS

- Keep user ticket queries scoped to the authenticated user.
- Keep admin ticket queries and check-in writes restricted to admin users.
- Confirm the existing RLS policies support:
  - Users selecting their own tickets.
  - Admins selecting all tickets.
  - Admins inserting check-ins.
  - Admins updating ticket `boarding_status`.
- If admin ticket status updates are not allowed by existing RLS, add a migration to allow admins to update tickets.
- Do not allow regular users to check tickets in.

## UI/UX Requirements

- Match the current app style: existing layouts, `glass-panel`, `badge-soft`, `btn-tf-primary`, and current spacing patterns.
- Keep the user ticket page focused on the actual tickets, not marketing content.
- Keep the admin page operational and dense enough for repeated use.
- Avoid nested cards.
- Make selected ticket state obvious.
- Make invalid scan results obvious and actionable.
- Ensure mobile layout works:
  - Ticket list stacks above details.
  - QR image remains readable.
  - Admin scanner and table do not overflow horizontally without a controlled scroll container.

## Edge Cases

Handle these without uncaught errors:

- User has no tickets.
- Ticket ID from the query string does not exist.
- QR payload is unknown.
- QR payload is valid but ticket is expired.
- QR payload is valid but ticket is already checked in.
- Camera permission is denied.
- Browser has no camera support.
- Supabase request fails.
- Ticket has missing related route/seat/profile data.

## Acceptance Criteria

- `/ticket` shows all purchased tickets for the signed-in user.
- Clicking a ticket updates the detail panel.
- `/ticket?ticketId=<id>` opens with that ticket selected when accessible.
- The selected ticket displays a QR code and detailed ticket metadata.
- Admins can see all tickets from the admin interface.
- Admins can start and stop camera scanning.
- Scanning a valid, unexpired, unchecked ticket checks it in.
- Scanning an expired ticket does not check it in and shows an expired result.
- Scanning an already checked-in ticket does not create a duplicate check-in.
- Ticket expiry is computed consistently through a shared helper.
- The UI includes loading, empty, success, and error states.
- RLS/migrations are updated if required for admin check-in status updates.
- Run the relevant checks before finishing, such as `npm run build`, and fix any build errors.

## Suggested Implementation Order

1. Inspect existing Supabase schema and current store mapping.
2. Create ticket timeline/status helper.
3. Add user ticket list and selected-ticket state.
4. Add or refactor ticket detail rendering.
5. Add admin ticket query and table.
6. Add QR scanner component/panel.
7. Add check-in mutation flow with duplicate and expiry guards.
8. Add any missing RLS migration.
9. Test user and admin flows.
10. Run the build and resolve issues.

## Notes

- Keep changes scoped to the ticket and admin ticket workflows.
- Reuse existing components when they fit, but split out focused components if a view becomes too large.
- Prefer clear, maintainable data mapping over clever inline template logic.
- Add short comments only where date fallback behavior or QR validation rules would otherwise be unclear.
