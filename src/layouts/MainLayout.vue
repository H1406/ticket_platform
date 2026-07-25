<script setup>
import AgentChatWindow from '@/components/common/AgentChatWindow.vue'
import AppNavbar from '@/components/common/AppNavbar.vue'
import AppFooter from '@/components/common/AppFooter.vue'
</script>

<template>
  <div class="app-shell d-flex min-vh-100 flex-column">
    <AppNavbar />
    <main class="flex-grow-1 position-relative">
      <slot />
    </main>
    <AppFooter />
    <AgentChatWindow />
  </div>
</template>
