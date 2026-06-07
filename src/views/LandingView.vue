<script setup>
import FeatureCard from '@/components/common/FeatureCard.vue'
import HeroMetrics from '@/components/common/HeroMetrics.vue'
import SectionHeading from '@/components/common/SectionHeading.vue'
import MainLayout from '@/layouts/MainLayout.vue'

const features = [
  {
    icon: '01',
    title: 'Realtime booking',
    description: 'Live inventory-aware booking journeys for rail and flight operators.'
  },
  {
    icon: '02',
    title: 'Live seat tracking',
    description: 'Seat map architecture prepared for distributed locks and instant availability updates.'
  },
  {
    icon: '03',
    title: 'QR boarding',
    description: 'Digital ticketing with future-ready QR issuance and gate validation hooks.'
  },
  {
    icon: '04',
    title: 'Smart booking assistant',
    description: 'Conversational booking workflows are scaffolded for future assistant-driven reservations.'
  }
]

const metrics = [
  { label: 'Tickets synced daily', value: '24k+' },
  { label: 'Average search response goal', value: '<200ms' },
  { label: 'Seat lock architecture', value: 'Ready' },
  { label: 'Operator view', value: 'Unified' }
]
</script>

<template>
  <MainLayout>
    <section class="page-section position-relative overflow-hidden">
      <div class="hero-orb orb-a"></div>
      <div class="hero-orb orb-b"></div>
      <div class="hero-orb orb-c"></div>

      <div class="container py-lg-5">
        <div class="row align-items-center g-5">
          <div class="col-lg-7">
            <span class="eyebrow mb-3">Modern Transit Operations</span>
            <h1 class="display-3 fw-bold lh-1 mb-4">
              Ticket booking and boarding that feels
              <span class="gradient-text">instantly alive</span>.
            </h1>
            <p class="section-copy fs-5 mb-4">
              TransitFlow is a frontend-first SaaS MVP for railway and flight teams who need elegant booking flows, seat visibility, QR boarding, and future realtime orchestration.
            </p>
            <div class="d-flex flex-column flex-sm-row gap-3">
              <RouterLink to="/auth" class="btn btn-tf-primary">Start Booking</RouterLink>
              <RouterLink to="/dashboard" class="btn btn-tf-secondary">Explore Dashboard</RouterLink>
            </div>

            <HeroMetrics :metrics="metrics" />
          </div>

          <div class="col-lg-5">
            <div class="glass-panel-strong p-4 p-lg-5">
              <div class="d-flex justify-content-between align-items-center mb-4">
                <div>
                  <div class="small text-muted-soft">Live booking cockpit</div>
                  <h2 class="h4 mb-0">TransitFlow control layer</h2>
                </div>
                <span class="badge-soft">Realtime-ready</span>
              </div>

              <div class="d-flex flex-column gap-3">
                <div class="glass-panel p-3">
                  <div class="d-flex justify-content-between mb-2">
                    <span class="text-muted-soft">Seat availability sync</span>
                    <strong class="text-success">Stable</strong>
                  </div>
                  <div class="progress bg-dark-subtle" role="progressbar">
                    <div class="progress-bar bg-info" style="width: 84%"></div>
                  </div>
                </div>
                <div class="glass-panel p-3">
                  <div class="d-flex justify-content-between">
                    <span class="text-muted-soft">Boarding status feed</span>
                    <strong>Gate A6</strong>
                  </div>
                </div>
                <div class="glass-panel p-3">
                  <div class="d-flex justify-content-between">
                    <span class="text-muted-soft">Assistant queue</span>
                    <strong>Future module</strong>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <section class="page-section">
      <div class="container">
        <SectionHeading
          eyebrow="What’s Included"
          title="A polished MVP foundation for modern mobility teams"
          copy="This first draft focuses on architecture, responsive UX, Supabase authentication, and scalable frontend patterns that can absorb advanced realtime features later."
        />

        <div class="row g-4">
          <div v-for="feature in features" :key="feature.title" class="col-md-6 col-xl-3">
            <FeatureCard v-bind="feature" />
          </div>
        </div>
      </div>
    </section>
  </MainLayout>
</template>
