<script setup>
import { computed, nextTick, ref } from 'vue'
import { assistantApi } from '@/services/api'

const isOpen = ref(false)
const draft = ref('')
const isSending = ref(false)
const errorMessage = ref('')
const statusMessage = ref('')
const messagesEl = ref(null)
const messages = ref([
  {
    id: crypto.randomUUID(),
    role: 'assistant',
    text: 'Hi, I can help you search routes, compare trips, and book tickets.'
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

async function sendMessage() {
  const message = draft.value.trim()

  if (!message || isSending.value) {
    return
  }

  const userMessage = {
    id: crypto.randomUUID(),
    role: 'user',
    text: message
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
      history: messages.value.map(({ role, text }) => ({ role, content: text }))
    })

    const reply = data?.reply || data?.message || data?.content

    if (reply) {
      messages.value.push({
        id: crypto.randomUUID(),
        role: 'assistant',
        text: reply
      })
    } else if (data?.accepted) {
      statusMessage.value = 'Message sent to assistant route.'
    }
  } catch (error) {
    errorMessage.value = error.response?.data?.message || 'Assistant route is not ready yet.'
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
            {{ message.text }}
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
