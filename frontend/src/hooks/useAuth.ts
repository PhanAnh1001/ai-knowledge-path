import { useAuthStore } from '@/store/authStore'

/**
 * Hook tiện lợi để kiểm tra trạng thái auth và thực hiện logout.
 */
export function useAuth() {
  return useAuthStore((s) => ({
    isAuthenticated: s.isAuthenticated,
    displayName: s.displayName,
    explorerType: s.explorerType,
    ageGroup: s.ageGroup,
    premium: s.premium,
    logout: s.logout,
  }))
}
