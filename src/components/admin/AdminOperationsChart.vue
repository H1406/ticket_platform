<script setup>
defineProps({
  metrics: {
    type: Array,
    default: () => []
  }
})
</script>

<template>
  <div class="operations-chart">
    <div
      v-for="metric in metrics"
      :key="metric.key"
      class="operations-chart-row"
    >
      <div class="operations-chart-copy">
        <div class="fw-semibold">{{ metric.label }}</div>
        <div class="text-muted-soft small">{{ metric.detail }}</div>
      </div>
      <div class="operations-chart-track" :aria-label="`${metric.label}: ${metric.value}`">
        <div
          class="operations-chart-fill"
          :class="metric.tone"
          :style="{ width: `${metric.percent}%` }"
        ></div>
      </div>
      <div class="operations-chart-value">{{ metric.value }}</div>
    </div>
  </div>
</template>

<style scoped>
.operations-chart {
  display: grid;
  gap: 20px;
  min-height: 220px;
}

.operations-chart-row {
  display: grid;
  grid-template-columns: minmax(150px, 1fr) minmax(160px, 2fr) 84px;
  gap: 16px;
  align-items: center;
}

.operations-chart-copy {
  min-width: 0;
}

.operations-chart-track {
  height: 18px;
  overflow: hidden;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.08);
}

.operations-chart-fill {
  height: 100%;
  min-width: 6px;
  border-radius: inherit;
  transition: width 0.25s ease;
}

.operations-chart-fill.info {
  background: linear-gradient(90deg, #4dd2ff, #7ef9c6);
}

.operations-chart-fill.success {
  background: linear-gradient(90deg, #39d98a, #b8f7d3);
}

.operations-chart-fill.warning {
  background: linear-gradient(90deg, #ffbd59, #ffd891);
}

.operations-chart-value {
  font-variant-numeric: tabular-nums;
  font-weight: 700;
  text-align: right;
}

@media (max-width: 767px) {
  .operations-chart-row {
    grid-template-columns: 1fr;
    gap: 8px;
  }

  .operations-chart-value {
    text-align: left;
  }
}
</style>
