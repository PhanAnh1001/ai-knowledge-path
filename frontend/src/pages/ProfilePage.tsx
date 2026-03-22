import { useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { getMe } from '@/api/auth'
import { useAuthStore } from '@/store/authStore'
import { Button } from '@/components/ui/Button'

const EXPLORER_LABELS: Record<string, string> = {
  nature:     '🌿 Khám phá tự nhiên',
  technology: '⚡ Công nghệ & Khoa học',
  history:    '🏛️ Lịch sử & Văn minh',
  creative:   '🎨 Sáng tạo & Tư duy',
}

const AGE_LABELS: Record<string, string> = {
  child_8_10:   '8–10 tuổi',
  teen_11_17:   '11–17 tuổi',
  adult_18_plus: '18+ tuổi',
}

export function ProfilePage() {
  const navigate = useNavigate()
  const logout = useAuthStore((s) => s.logout)

  const { data: profile, isLoading, isError } = useQuery({
    queryKey: ['me'],
    queryFn: getMe,
  })

  const handleLogout = () => {
    logout()
    navigate('/login', { replace: true })
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="sticky top-0 z-10 border-b bg-white px-6 py-4">
        <div className="mx-auto flex max-w-2xl items-center justify-between">
          <button
            onClick={() => navigate('/dashboard')}
            className="text-sm text-gray-500 hover:text-gray-800 transition-colors"
          >
            ← Quay lại
          </button>
          <h1 className="text-base font-semibold text-gray-900">Hồ sơ</h1>
          <div className="w-16" /> {/* spacer */}
        </div>
      </header>

      <main className="mx-auto max-w-2xl px-6 py-10">
        {isLoading && (
          <div className="space-y-4">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="h-14 animate-pulse rounded-xl bg-gray-200" />
            ))}
          </div>
        )}

        {isError && (
          <div className="rounded-xl border border-red-200 bg-red-50 p-6 text-center text-red-600">
            Không thể tải thông tin. Vui lòng thử lại.
          </div>
        )}

        {profile && (
          <div className="space-y-6">
            {/* Avatar + name */}
            <div className="flex flex-col items-center gap-3 pb-4">
              <div className="flex h-20 w-20 items-center justify-center rounded-full bg-primary-100 text-4xl">
                {EXPLORER_LABELS[profile.explorerType]?.charAt(0) ?? '🧭'}
              </div>
              <div className="text-center">
                <h2 className="text-2xl font-bold text-gray-900">{profile.displayName}</h2>
                <p className="text-sm text-gray-500">{profile.email}</p>
              </div>
            </div>

            {/* Stats */}
            <div className="rounded-2xl border bg-white p-6 shadow-sm">
              <h3 className="mb-4 text-xs font-semibold uppercase tracking-wide text-gray-400">
                Thông tin
              </h3>
              <dl className="space-y-4">
                <ProfileRow label="Loại nhà thám hiểm" value={EXPLORER_LABELS[profile.explorerType] ?? profile.explorerType} />
                <ProfileRow label="Nhóm tuổi" value={AGE_LABELS[profile.ageGroup] ?? profile.ageGroup} />
                <ProfileRow label="Số session đã hoàn thành" value={profile.totalSessions.toString()} />
                <ProfileRow
                  label="Gói dịch vụ"
                  value={profile.premium ? '⭐ Premium' : 'Free'}
                />
              </dl>
            </div>

            {/* Logout */}
            <Button
              variant="secondary"
              className="w-full"
              onClick={handleLogout}
            >
              Đăng xuất
            </Button>
          </div>
        )}
      </main>
    </div>
  )
}

function ProfileRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between">
      <dt className="text-sm text-gray-500">{label}</dt>
      <dd className="text-sm font-medium text-gray-900">{value}</dd>
    </div>
  )
}
