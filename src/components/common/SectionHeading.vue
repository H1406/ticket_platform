<script setup>
defineProps({
  eyebrow: String,
  title: String,
  copy: String
})
</script>

<template>
  <div class="mb-4 mb-lg-5">
    <span v-if="eyebrow" class="eyebrow mb-3">{{ eyebrow }}</span>
    <h2 class="section-title mb-3">{{ title }}</h2>
    <p v-if="copy" class="section-copy mb-0">{{ copy }}</p>
  </div>
</template>
