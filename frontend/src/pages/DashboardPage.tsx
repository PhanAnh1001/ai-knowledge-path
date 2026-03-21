import { useQuery } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { getNodes } from '@/api/nodes'
import { useAuthStore } from '@/store/authStore'
import { NodeCard } from '@/components/session/NodeCard'
import { Button } from '@/components/ui/Button'

export function DashboardPage() {
  const navigate = useNavigate()
  const { displayName, explorerType, logout } = useAuthStore((s) => ({
    displayName: s.displayName,
    explorerType: s.explorerType,
    logout: s.logout,
  }))

  const { data: nodes, isLoading } = useQuery({
    queryKey: ['nodes', explorerType],
    queryFn: () => getNodes(explorerType ?? undefined),
  })

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="border-b bg-white px-6 py-4">
        <div className="mx-auto flex max-w-4xl items-center justify-between">
          <div>
            <h1 className="text-xl font-bold text-gray-900">AI Wisdom Battle</h1>
            <p className="text-sm text-gray-500">Xin chào, {displayName} 👋</p>
          </div>
          <Button variant="ghost" onClick={handleLogout}>
            Đăng xuất
          </Button>
        </div>
      </header>

      <main className="mx-auto max-w-4xl px-6 py-8">
        <div className="mb-6">
          <h2 className="text-2xl font-bold text-gray-900">Khám phá hôm nay</h2>
          <p className="mt-1 text-gray-500">Chọn một chủ đề để bắt đầu hành trình</p>
        </div>

        {isLoading && (
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="h-48 animate-pulse rounded-xl bg-gray-200" />
            ))}
          </div>
        )}

        {nodes && nodes.length > 0 && (
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {nodes.map((node) => (
              <NodeCard key={node.id} node={node} />
            ))}
          </div>
        )}

        {nodes && nodes.length === 0 && (
          <div className="rounded-xl border border-dashed border-gray-300 py-16 text-center text-gray-500">
            <p className="text-lg">Chưa có nội dung nào</p>
            <p className="text-sm mt-1">Quay lại sau nhé!</p>
          </div>
        )}
      </main>
    </div>
  )
}
