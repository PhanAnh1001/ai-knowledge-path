import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { AgeGroup, ExplorerType } from '@/types'

interface AuthState {
  token: string | null
  userId: string | null
  displayName: string | null
  explorerType: ExplorerType | null
  ageGroup: AgeGroup | null
  premium: boolean
  isAuthenticated: boolean

  setAuth: (payload: {
    token: string
    userId: string
    displayName: string
    explorerType: ExplorerType
    ageGroup: AgeGroup
    premium: boolean
  }) => void
  logout: () => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      userId: null,
      displayName: null,
      explorerType: null,
      ageGroup: null,
      premium: false,
      isAuthenticated: false,

      setAuth: (payload) =>
        set({
          token: payload.token,
          userId: payload.userId,
          displayName: payload.displayName,
          explorerType: payload.explorerType,
          ageGroup: payload.ageGroup,
          premium: payload.premium,
          isAuthenticated: true,
        }),

      logout: () =>
        set({
          token: null,
          userId: null,
          displayName: null,
          explorerType: null,
          ageGroup: null,
          premium: false,
          isAuthenticated: false,
        }),
    }),
    { name: 'auth-storage' },
  ),
)
