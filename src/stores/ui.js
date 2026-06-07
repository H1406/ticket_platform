import { defineStore } from 'pinia'

export const useUiStore = defineStore('ui', {
  state: () => ({
    notifications: [],
    activeTheme: 'dark'
  }),
  actions: {
    pushNotification(notification) {
      this.notifications.unshift({
        id: crypto.randomUUID(),
        createdAt: new Date().toISOString(),
        ...notification
      })
    }
  }
})
