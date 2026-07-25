import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://placeholder.supabase.co'
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'placeholder-anon-key'

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
    flowType: 'pkce'
  }
})

export const dbTables = {
  users: ['id', 'email', 'first_name', 'last_name', 'avatar_url', 'role', 'created_at'],
  routes: ['id', 'transport_type', 'departure', 'destination', 'departure_time', 'arrival_time'],
  vehicles: ['id', 'route_id', 'vehicle_code', 'vehicle_type', 'capacity', 'deck_layout'],
  seats: [
    'id',
    'vehicle_id',
    'seat_code',
    'seat_class',
    'status',
    'held_by_booking_id',
    'held_by_user_id',
    'hold_expires_at',
    'position_meta'
  ],
  bookings: ['id', 'user_id', 'route_id', 'seat_ids', 'status', 'travel_date', 'hold_expires_at'],
  tickets: ['id', 'booking_id', 'qr_payload', 'boarding_status', 'issued_at'],
  checkins: ['id', 'ticket_id', 'checked_in_at', 'gate', 'agent_id'],
  notifications: ['id', 'user_id', 'title', 'message', 'channel', 'read_at']
}
