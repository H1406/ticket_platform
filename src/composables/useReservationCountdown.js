import { computed, onBeforeUnmount, onMounted, ref } from 'vue'

export function useReservationCountdown(expiresAt) {
  const now = ref(Date.now())
  let timerId

  const remainingMs = computed(() => Math.max(expiresAt.value - now.value, 0))
  const minutes = computed(() => String(Math.floor(remainingMs.value / 60000)).padStart(2, '0'))
  const seconds = computed(() =>
    String(Math.floor((remainingMs.value % 60000) / 1000)).padStart(2, '0')
  )
  const isExpired = computed(() => remainingMs.value === 0)

  onMounted(() => {
    timerId = window.setInterval(() => {
      now.value = Date.now()
    }, 1000)
  })

  onBeforeUnmount(() => {
    window.clearInterval(timerId)
  })

  return {
    minutes,
    seconds,
    isExpired
  }
}
