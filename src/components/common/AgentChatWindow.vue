<script setup>
import { computed, nextTick, ref } from 'vue'
import { assistantApi } from '@/services/api'

const isOpen = ref(false)
const draft = ref('')
const isSending = ref(false)
const errorMessage = ref('')
const statusMessage = ref('')
const messagesEl = ref(null)
const assistantState = ref({})
const messages = ref([
  {
    id: crypto.randomUUID(),
    role: 'assistant',
    text: 'Hi, I can help you search routes, compare trips, and book tickets.',
    details: null
  }
])

const canSend = computed(() => draft.value.trim().length > 0 && !isSending.value)

function toggleChat() {
  isOpen.value = !isOpen.value
  if (isOpen.value) {
    nextTick(scrollToLatest)
  }
}

function scrollToLatest() {
  if (messagesEl.value) {
    messagesEl.value.scrollTop = messagesEl.value.scrollHeight
  }
}

function extractJsonObject(text) {
  const source = String(text || '')
  const markerIndex = source.indexOf('Please confirm this booking payload:')
  const startIndex = source.indexOf('{', markerIndex >= 0 ? markerIndex : 0)

  if (startIndex < 0) {
    return null
  }

  let depth = 0
  let inString = false
  let escaped = false

  for (let index = startIndex; index < source.length; index += 1) {
    const char = source[index]

    if (escaped) {
      escaped = false
      continue
    }

    if (char === '\\') {
      escaped = true
      continue
    }

    if (char === '"') {
      inString = !inString
      continue
    }

    if (inString) {
      continue
    }

    if (char === '{') {
      depth += 1
    } else if (char === '}') {
      depth -= 1
      if (depth === 0) {
        const rawJson = source.slice(startIndex, index + 1)
        try {
          return {
            parsed: JSON.parse(rawJson),
            raw: rawJson
          }
        } catch {
          return null
        }
      }
    }
  }

  return null
}

function cleanAssistantText(text, rawJson) {
  if (!rawJson) {
    return text
  }

  return String(text)
    .replace('Please confirm this booking payload:', 'Review the booking details below.')
    .replace(rawJson, '')
    .replace(/\n{3,}/g, '\n\n')
    .trim()
}

function formatRouteLabel(route) {
  if (!route) {
    return ''
  }

  const endpoints = [route.departure, route.destination].filter(Boolean).join(' -> ')
  return [endpoints, route.transport_type].filter(Boolean).join(' · ')
}

function buildAssistantDetails(data, reply) {
  const extractedJson = extractJsonObject(reply)
  const pendingPayload = data?.payload || extractedJson?.parsed || null
  const confirmation = data?.booking || null

  if (confirmation) {
    return {
      kind: 'confirmed',
      title: 'Booking confirmed',
      summary: confirmation.ticket_id ? `Ticket ${confirmation.ticket_id}` : 'Ticket issued',
      rows: [
        { label: 'Booking', value: confirmation.booking_id },
        { label: 'Ticket', value: confirmation.ticket_id },
        { label: 'Status', value: confirmation.status || 'Confirmed' }
      ].filter((row) => row.value)
    }
  }

  if (!pendingPayload) {
    return null
  }

  const route = pendingPayload.route || {}

  return {
    kind: data?.needsConfirmation ? 'pending' : 'summary',
    title: data?.needsConfirmation ? 'Booking hold' : 'Booking details',
    summary: formatRouteLabel(route),
    seats: pendingPayload.seat_codes || [],
    rows: [
      { label: 'Travel date', value: pendingPayload.travel_date },
      { label: 'Departure', value: route.departure_time },
      { label: 'Arrival', value: route.arrival_time },
      { label: 'Passengers', value: pendingPayload.passenger_count },
      { label: 'Vehicle', value: route.vehicle_code },
      { label: 'Booking', value: pendingPayload.booking_id }
    ].filter((row) => row.value)
  }
}

function buildAssistantMessage(data) {
  const reply = data?.reply || data?.message || data?.content || ''
  const extractedJson = extractJsonObject(reply)

  return {
    id: crypto.randomUUID(),
    role: 'assistant',
    text: cleanAssistantText(reply, extractedJson?.raw),
    details: buildAssistantDetails(data, reply)
  }
}

async function sendMessage() {
  const message = draft.value.trim()

  if (!message || isSending.value) {
    return
  }

  const userMessage = {
    id: crypto.randomUUID(),
    role: 'user',
    text: message,
    details: null
  }

  messages.value.push(userMessage)
  draft.value = ''
  errorMessage.value = ''
  statusMessage.value = ''
  isSending.value = true

  await nextTick(scrollToLatest)

  try {
    const { data } = await assistantApi.sendMessage({
      message,
      history: messages.value.map(({ role, text }) => ({ role, content: text })),
      state: assistantState.value
    })

    assistantState.value = data?.state || assistantState.value || {}

    if (data?.reply || data?.message || data?.content || data?.payload || data?.booking) {
      messages.value.push(buildAssistantMessage(data))
    } else if (data?.accepted) {
      statusMessage.value = 'Message sent to assistant route.'
    }
  } catch (error) {
    const message = error.response?.data?.message || error.message || 'Assistant route is not ready yet.'
    errorMessage.value = message
    messages.value.push({
      id: crypto.randomUUID(),
      role: 'assistant',
      text: message,
      details: null
    })
  } finally {
    isSending.value = false
    await nextTick(scrollToLatest)
  }
}
</script>

<template>
  <div class="agent-chat">
    <transition name="transition-fade">
      <section v-if="isOpen" class="agent-chat__panel glass-panel-strong" aria-label="Booking assistant chat">
        <header class="agent-chat__header">
          <div>
            <p class="agent-chat__eyebrow mb-1">Booking assistant</p>
            <h2 class="h6 mb-0">Need help choosing a ticket?</h2>
          </div>
          <button
            type="button"
            class="agent-chat__icon-button"
            aria-label="Close booking assistant"
            title="Close"
            @click="toggleChat"
          >
            x
          </button>
        </header>

        <div ref="messagesEl" class="agent-chat__messages" aria-live="polite">
          <div
            v-for="message in messages"
            :key="message.id"
            class="agent-chat__message"
            :class="`agent-chat__message--${message.role}`"
          >
            <p v-if="message.text" class="agent-chat__message-text mb-0">{{ message.text }}</p>

            <div v-if="message.details" class="agent-chat__output" :class="`agent-chat__output--${message.details.kind}`">
              <div class="agent-chat__output-header">
                <div>
                  <div class="agent-chat__output-title">{{ message.details.title }}</div>
                  <div v-if="message.details.summary" class="agent-chat__output-summary">
                    {{ message.details.summary }}
                  </div>
                </div>
                <span class="agent-chat__output-state">
                  {{ message.details.kind === 'confirmed' ? 'Done' : 'Held' }}
                </span>
              </div>

              <div v-if="message.details.seats?.length" class="agent-chat__seat-row">
                <span
                  v-for="seat in message.details.seats"
                  :key="seat"
                  class="agent-chat__seat-chip"
                >
                  {{ seat }}
                </span>
              </div>

              <dl class="agent-chat__detail-grid mb-0">
                <template v-for="row in message.details.rows" :key="row.label">
                  <dt>{{ row.label }}</dt>
                  <dd>{{ row.value }}</dd>
                </template>
              </dl>
            </div>
          </div>
        </div>

        <p v-if="errorMessage" class="agent-chat__status mb-0">
          {{ errorMessage }}
        </p>
        <p v-else-if="statusMessage" class="agent-chat__status mb-0">
          {{ statusMessage }}
        </p>
        <p v-else-if="isSending" class="agent-chat__status mb-0">
          Sending to assistant route...
        </p>

        <form class="agent-chat__composer" @submit.prevent="sendMessage">
          <textarea
            v-model="draft"
            class="agent-chat__input"
            rows="2"
            placeholder="Ask about destinations, schedules, or booking..."
            aria-label="Message booking assistant"
            @keydown.enter.exact.prevent="sendMessage"
          ></textarea>
          <button
            type="submit"
            class="agent-chat__send"
            :disabled="!canSend"
            aria-label="Send message"
            title="Send"
          >
            Send
          </button>
        </form>
      </section>
    </transition>

    <button
      type="button"
      class="agent-chat__launcher"
      :aria-expanded="isOpen"
      aria-label="Open booking assistant"
      title="Booking assistant"
      @click="toggleChat"
    >
      AI
    </button>
  </div>
</template>

<style scoped>
.agent-chat {
  position: fixed;
  right: max(18px, env(safe-area-inset-right));
  bottom: max(18px, env(safe-area-inset-bottom));
  z-index: 20;
}

.agent-chat__panel {
  display: flex;
  flex-direction: column;
  width: min(380px, calc(100vw - 36px));
  height: min(560px, calc(100vh - 112px));
  margin-bottom: 16px;
  overflow: hidden;
  border-radius: var(--tf-radius-md);
}

.agent-chat__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 1rem;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.agent-chat__eyebrow {
  color: var(--tf-primary);
  font-size: 0.74rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.agent-chat__icon-button,
.agent-chat__launcher,
.agent-chat__send {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 0;
  font-weight: 700;
}

.agent-chat__icon-button {
  width: 34px;
  height: 34px;
  flex: 0 0 34px;
  border-radius: 999px;
  color: var(--tf-text);
  background: rgba(255, 255, 255, 0.08);
}

.agent-chat__messages {
  display: flex;
  flex: 1;
  flex-direction: column;
  gap: 0.75rem;
  min-height: 0;
  padding: 1rem;
  overflow-y: auto;
}

.agent-chat__message {
  max-width: 86%;
  padding: 0.75rem 0.9rem;
  border-radius: 16px;
  font-size: 0.92rem;
  line-height: 1.45;
  overflow-wrap: anywhere;
}

.agent-chat__message-text {
  white-space: pre-line;
}

.agent-chat__message--assistant {
  align-self: flex-start;
  border: 1px solid rgba(255, 255, 255, 0.08);
  color: var(--tf-text);
  background: rgba(255, 255, 255, 0.07);
}

.agent-chat__message--user {
  align-self: flex-end;
  color: #02111a;
  background: linear-gradient(135deg, var(--tf-primary), #7ef9c6);
}

.agent-chat__output {
  display: grid;
  gap: 0.75rem;
  min-width: min(285px, calc(100vw - 92px));
  margin-top: 0.75rem;
  padding: 0.85rem;
  border: 1px solid rgba(77, 210, 255, 0.18);
  border-radius: var(--tf-radius-sm);
  background: rgba(2, 17, 26, 0.34);
}

.agent-chat__output--confirmed {
  border-color: rgba(57, 217, 138, 0.28);
  background: rgba(57, 217, 138, 0.08);
}

.agent-chat__output-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 0.75rem;
}

.agent-chat__output-title {
  color: var(--tf-text);
  font-size: 0.9rem;
  font-weight: 800;
}

.agent-chat__output-summary {
  margin-top: 0.1rem;
  color: var(--tf-text-muted);
  font-size: 0.8rem;
}

.agent-chat__output-state {
  flex: 0 0 auto;
  padding: 0.22rem 0.5rem;
  border-radius: 999px;
  color: #02111a;
  background: var(--tf-primary);
  font-size: 0.72rem;
  font-weight: 800;
}

.agent-chat__output--confirmed .agent-chat__output-state {
  background: var(--tf-success);
}

.agent-chat__seat-row {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem;
}

.agent-chat__seat-chip {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 34px;
  height: 30px;
  padding: 0 0.55rem;
  border: 1px solid rgba(255, 255, 255, 0.14);
  border-radius: 8px;
  color: var(--tf-text);
  background: rgba(255, 255, 255, 0.08);
  font-size: 0.82rem;
  font-weight: 800;
}

.agent-chat__detail-grid {
  display: grid;
  grid-template-columns: max-content minmax(0, 1fr);
  gap: 0.38rem 0.8rem;
}

.agent-chat__detail-grid dt,
.agent-chat__detail-grid dd {
  margin: 0;
  min-width: 0;
  font-size: 0.79rem;
}

.agent-chat__detail-grid dt {
  color: var(--tf-text-muted);
  font-weight: 600;
}

.agent-chat__detail-grid dd {
  color: var(--tf-text);
  font-weight: 700;
  overflow-wrap: anywhere;
}

.agent-chat__status {
  padding: 0 1rem 0.85rem;
  color: var(--tf-text-muted);
  font-size: 0.82rem;
}

.agent-chat__composer {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 0.75rem;
  padding: 1rem;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
}

.agent-chat__input {
  width: 100%;
  min-height: 46px;
  max-height: 110px;
  resize: vertical;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: var(--tf-radius-sm);
  padding: 0.72rem 0.85rem;
  color: var(--tf-text);
  background: rgba(255, 255, 255, 0.04);
}

.agent-chat__input:focus {
  border-color: rgba(77, 210, 255, 0.5);
  box-shadow: 0 0 0 0.2rem rgba(77, 210, 255, 0.1);
  outline: none;
}

.agent-chat__input::placeholder {
  color: rgba(229, 238, 255, 0.45);
}

.agent-chat__send {
  min-width: 68px;
  height: 46px;
  align-self: end;
  border-radius: 999px;
  color: #02111a;
  background: linear-gradient(135deg, var(--tf-primary), #7ef9c6);
}

.agent-chat__send:disabled {
  cursor: not-allowed;
  opacity: 0.55;
}

.agent-chat__launcher {
  width: 62px;
  height: 62px;
  margin-left: auto;
  border-radius: 999px;
  color: #02111a;
  background: linear-gradient(135deg, var(--tf-primary), #7ef9c6);
  box-shadow: 0 18px 40px rgba(77, 210, 255, 0.28);
}

@media (max-width: 575.98px) {
  .agent-chat {
    right: 12px;
    bottom: 12px;
    left: 12px;
  }

  .agent-chat__panel {
    width: 100%;
    height: min(520px, calc(100vh - 96px));
  }
}
</style>
