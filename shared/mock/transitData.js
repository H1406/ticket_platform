export const mockTrips = [
  {
    id: 'TRP-2041',
    route: 'Hanoi to Da Nang',
    mode: 'Rail Express',
    departure: '08:15',
    date: 'Jun 04',
    seat: 'Coach B · B4',
    status: 'boarding soon'
  },
  {
    id: 'FLT-8812',
    route: 'Ho Chi Minh City to Singapore',
    mode: 'SkyLine Air',
    departure: '19:40',
    date: 'Jun 10',
    seat: '12A',
    status: 'confirmed'
  },
  {
    id: 'TRP-1802',
    route: 'Hue to Nha Trang',
    mode: 'Night Rail',
    departure: '21:25',
    date: 'May 16',
    seat: 'Sleeper S2',
    status: 'completed'
  }
]

export const mockBookingHistory = [
  { id: 'BK-1001', route: 'Tokyo to Kyoto', amount: '$124', status: 'Completed' },
  { id: 'BK-1002', route: 'Paris to Amsterdam', amount: '$201', status: 'Refunded' },
  { id: 'BK-1003', route: 'Seoul to Busan', amount: '$86', status: 'Completed' }
]

export const mockLiveStats = [
  { label: 'Bookings Today', value: '1,284', change: '+14%' },
  { label: 'Live Occupancy', value: '82%', change: '+5.3%' },
  { label: 'Check-ins Synced', value: '349', change: 'Realtime-ready' },
  { label: 'Support Resolution', value: '97%', change: '+2.1%' }
]

export const mockNotifications = [
  {
    id: 1,
    title: 'Boarding gate moved',
    body: 'Flight SL-204 now departs from Gate A6.',
    tone: 'warning'
  },
  {
    id: 2,
    title: 'Seat hold active',
    body: 'Seat B4 is temporarily held for your booking flow.',
    tone: 'info'
  },
  {
    id: 3,
    title: 'Ticket issued',
    body: 'Your QR boarding pass has been generated.',
    tone: 'success'
  }
]

export const mockRoutes = [
  {
    id: 'route-1',
    type: 'train',
    operator: 'VeloRail Premium',
    departure: 'Hanoi',
    destination: 'Da Nang',
    departureTime: '08:15',
    arrivalTime: '14:20',
    price: '$64',
    duration: '6h 05m',
    class: 'Business'
  },
  {
    id: 'route-2',
    type: 'flight',
    operator: 'AeroVista',
    departure: 'Ho Chi Minh City',
    destination: 'Singapore',
    departureTime: '09:45',
    arrivalTime: '12:35',
    price: '$142',
    duration: '2h 50m',
    class: 'Economy Flex'
  },
  {
    id: 'route-3',
    type: 'train',
    operator: 'Lunar Line',
    departure: 'Hue',
    destination: 'Nha Trang',
    departureTime: '21:25',
    arrivalTime: '05:40',
    price: '$88',
    duration: '8h 15m',
    class: 'Sleeper'
  }
]

export const mockSeatMap = [
  { id: 'A1', x: 40, y: 40, status: 'available', class: 'window' },
  { id: 'A2', x: 120, y: 40, status: 'reserved', class: 'aisle' },
  { id: 'A3', x: 260, y: 40, status: 'occupied', class: 'aisle' },
  { id: 'A4', x: 340, y: 40, status: 'available', class: 'window' },
  { id: 'B1', x: 40, y: 120, status: 'available', class: 'window' },
  { id: 'B2', x: 120, y: 120, status: 'available', class: 'aisle' },
  { id: 'B3', x: 260, y: 120, status: 'reserved', class: 'aisle' },
  { id: 'B4', x: 340, y: 120, status: 'selected', class: 'window' },
  { id: 'C1', x: 40, y: 200, status: 'occupied', class: 'window' },
  { id: 'C2', x: 120, y: 200, status: 'available', class: 'aisle' },
  { id: 'C3', x: 260, y: 200, status: 'available', class: 'aisle' },
  { id: 'C4', x: 340, y: 200, status: 'available', class: 'window' },
  { id: 'D1', x: 40, y: 280, status: 'available', class: 'window' },
  { id: 'D2', x: 120, y: 280, status: 'available', class: 'aisle' },
  { id: 'D3', x: 260, y: 280, status: 'reserved', class: 'aisle' },
  { id: 'D4', x: 340, y: 280, status: 'available', class: 'window' }
]

export const mockTicket = {
  id: 'TKT-203014',
  passenger: 'Alex Morgan',
  route: 'Hanoi → Da Nang',
  operator: 'VeloRail Premium',
  departureDate: 'June 4, 2026',
  departureTime: '08:15',
  arrivalTime: '14:20',
  gate: 'Platform 05',
  seat: 'B4',
  class: 'Business',
  status: 'Boarding in 24 minutes'
}

export const mockPassengerTable = [
  { id: 'P-1001', name: 'Lena Howard', route: 'HN-DN', seat: 'B2', status: 'Checked in' },
  { id: 'P-1002', name: 'Zane Cole', route: 'SGN-SIN', seat: '14A', status: 'Pending' },
  { id: 'P-1003', name: 'Iris Kim', route: 'HUI-NTR', seat: 'S3', status: 'Boarded' },
  { id: 'P-1004', name: 'Mia Tran', route: 'HN-DN', seat: 'A4', status: 'Checked in' }
]
