<script setup>
import { computed, onMounted, ref } from 'vue'
import AdminLayout from '@/layouts/AdminLayout.vue'
import AdminTicketsTable from '@/components/admin/AdminTicketsTable.vue'
import QrScannerPanel from '@/components/admin/QrScannerPanel.vue'
import { useBookingStore } from '@/stores/booking'

const bookingStore = useBookingStore()

const searchTerm = ref('')
const statusFilter = ref('all')

const filteredTickets = computed(() => {
  const term = searchTerm.value.trim().toLowerCase()

  return bookingStore.adminTickets.filter((ticket) => {
    const matchesSearch =
      !term ||
      ticket.id.toLowerCase().includes(term) ||
      ticket.passenger.toLowerCase().includes(term) ||
      ticket.route.toLowerCase().includes(term)

    const matchesStatus =
      statusFilter.value === 'all' ||
      (statusFilter.value === 'checked_in' && ticket.isCheckedIn) ||
      (statusFilter.value === 'expired' && ticket.isExpired && !ticket.isCheckedIn) ||
      (statusFilter.value === 'valid' && !ticket.isExpired && !ticket.isCheckedIn) ||
      (statusFilter.value === 'cancelled' && ticket.status === 'cancelled')

    return matchesSearch && matchesStatus
  })
})

onMounted(async () => {
  await bookingStore.fetchAdminTickets()
})
</script>

<template>
  <AdminLayout>
    <div class="mb-4">
      <span class="eyebrow mb-3">Admin Console</span>
      <h1 class="section-title mb-3">Ticket operations</h1>
      <p class="section-copy mb-0">
        Review every issued ticket and check passengers in with a camera QR scan.
      </p>
    </div>

    <div class="row g-4 mb-4">
      <div class="col-lg-5">
        <QrScannerPanel />
      </div>
      <div class="col-lg-7">
        <div class="glass-panel p-4 h-100">
          <h3 class="h5 mb-3">Filters</h3>
          <div class="row g-2 mb-2">
            <div class="col-sm-7">
              <input
                v-model="searchTerm"
                type="search"
                class="form-control"
                placeholder="Search by ticket ID, passenger, or route"
              />
            </div>
            <div class="col-sm-5">
              <select v-model="statusFilter" class="form-select">
                <option value="all">All statuses</option>
                <option value="valid">Valid</option>
                <option value="checked_in">Checked in</option>
                <option value="expired">Expired</option>
                <option value="cancelled">Cancelled</option>
              </select>
            </div>
          </div>
          <div class="text-muted-soft small">
            {{ filteredTickets.length }} of {{ bookingStore.adminTickets.length }} tickets
          </div>
        </div>
      </div>
    </div>

    <div v-if="bookingStore.adminTicketsLoading" class="glass-panel p-4">
      <h3 class="h5 mb-2">Loading tickets</h3>
      <p class="text-muted-soft mb-0">Fetching all tickets from Supabase.</p>
    </div>
    <div v-else-if="bookingStore.adminTicketsError" class="glass-panel p-4">
      <h3 class="h5 mb-2">Unable to load tickets</h3>
      <p class="text-muted-soft mb-0">{{ bookingStore.adminTicketsError }}</p>
    </div>
    <div v-else-if="!bookingStore.adminTickets.length" class="glass-panel p-4">
      <h3 class="h5 mb-2">No tickets issued yet</h3>
      <p class="text-muted-soft mb-0">Tickets will appear here once passengers confirm bookings.</p>
    </div>
    <AdminTicketsTable v-else :tickets="filteredTickets" />
  </AdminLayout>
</template>
