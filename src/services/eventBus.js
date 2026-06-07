const listeners = new Map()

export function emitEvent(eventName, payload) {
  const callbacks = listeners.get(eventName) || []
  callbacks.forEach((callback) => callback(payload))
}

export function onEvent(eventName, callback) {
  const existing = listeners.get(eventName) || []
  listeners.set(eventName, [...existing, callback])

  return () => {
    const next = (listeners.get(eventName) || []).filter((item) => item !== callback)
    listeners.set(eventName, next)
  }
}
