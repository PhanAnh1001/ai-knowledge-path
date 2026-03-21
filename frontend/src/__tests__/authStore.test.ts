import { describe, it, expect, beforeEach } from 'vitest'
import { useAuthStore } from '@/store/authStore'

const mockPayload = {
  token: 'jwt-token-abc',
  userId: 'user-123',
  displayName: 'Nhà thám hiểm',
  explorerType: 'nature' as const,
  ageGroup: 'teen_11_17' as const,
  premium: false,
}

describe('authStore', () => {
  beforeEach(() => {
    // Reset store trước mỗi test
    useAuthStore.getState().logout()
  })

  it('initially not authenticated', () => {
    expect(useAuthStore.getState().isAuthenticated).toBe(false)
    expect(useAuthStore.getState().token).toBeNull()
  })

  it('setAuth sets all fields and isAuthenticated=true', () => {
    useAuthStore.getState().setAuth(mockPayload)
    const state = useAuthStore.getState()
    expect(state.isAuthenticated).toBe(true)
    expect(state.token).toBe('jwt-token-abc')
    expect(state.displayName).toBe('Nhà thám hiểm')
    expect(state.explorerType).toBe('nature')
  })

  it('logout clears all fields', () => {
    useAuthStore.getState().setAuth(mockPayload)
    useAuthStore.getState().logout()
    const state = useAuthStore.getState()
    expect(state.isAuthenticated).toBe(false)
    expect(state.token).toBeNull()
    expect(state.userId).toBeNull()
  })
})
