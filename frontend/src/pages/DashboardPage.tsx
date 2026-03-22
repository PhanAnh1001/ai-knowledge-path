import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { getNodes } from '@/api/nodes'
import { useAuthStore } from '@/store/authStore'
import { NodeCard } from '@/components/session/NodeCard'
import { Button } from '@/components/ui/Button'
import { clsx } from 'clsx'
import type { ExplorerType } from '@/types'

type DomainFilter = 'all' | ExplorerType

const DOMAIN_TABS: { value: DomainFilter; label: string; emoji: string }[] = [
  { value: 'all',        label: 'Tất cả',     emoji: '🔍' },
  { value: 'nature',     label: 'Tự nhiên',   emoji: '🌿' },
  { value: 'technology', label: 'Công nghệ',  emoji: '⚡' },
  { value: 'history',    label: 'Lịch sử',    emoji: '🏛️' },
  { value: 'creative',   label: 'Sáng tạo',   emoji: '🎨' },
]

export function DashboardPage() {
  const navigate = useNavigate()
  const displayName = useAuthStore((s) => s.displayName)

  const [activeTab, setActiveTab] = useState<DomainFilter>('all')

  // Fetch all nodes once; filter client-side to avoid extra requests
  const { data: nodes, isLoading } = useQuery({
    queryKey: ['nodes'],
    queryFn: () => getNodes(),
  })


  const filtered =
    !nodes ? [] :
    activeTab === 'all' ? nodes :
    nodes.filter((n) => n.domain.toLowerCase() === activeTab)

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="sticky top-0 z-10 border-b bg-white px-6 py-4">
        <div className="mx-auto flex max-w-4xl items-center justify-between">
          <div>
            <h1 className="text-lg font-bold text-gray-900">AI Wisdom Battle</h1>
            <p className="text-sm text-gray-500">Xin chào, {displayName} 👋</p>
          </div>
          <Button variant="ghost" onClick={() => navigate('/profile')} className="text-sm">
            Hồ sơ
          </Button>
        </div>
      </header>

      <main className="mx-auto max-w-4xl px-6 py-8">
        <div className="mb-6">
          <h2 className="text-2xl font-bold text-gray-900">Khám phá hôm nay</h2>
          <p className="mt-1 text-gray-500 text-sm">Chọn một chủ đề để bắt đầu hành trình</p>
        </div>

        {/* Domain filter tabs */}
        <div className="mb-6 flex gap-2 overflow-x-auto pb-1">
          {DOMAIN_TABS.map((tab) => (
            <button
              key={tab.value}
              onClick={() => setActiveTab(tab.value)}
              className={clsx(
                'flex-shrink-0 flex items-center gap-1.5 rounded-full px-4 py-2 text-sm font-medium transition-colors',
                activeTab === tab.value
                  ? 'bg-primary-600 text-white'
                  : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50',
              )}
            >
              <span>{tab.emoji}</span>
              <span>{tab.label}</span>
            </button>
          ))}
        </div>

        {/* Node grid */}
        {isLoading && (
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="h-52 animate-pulse rounded-xl bg-gray-200" />
            ))}
          </div>
        )}

        {!isLoading && filtered.length > 0 && (
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {filtered.map((node) => (
              <NodeCard key={node.id} node={node} />
            ))}
          </div>
        )}

        {!isLoading && filtered.length === 0 && (
          <div className="rounded-xl border border-dashed border-gray-300 py-16 text-center text-gray-500">
            <p className="text-lg">Chưa có nội dung nào</p>
            <p className="text-sm mt-1">
              {activeTab === 'all'
                ? 'Quay lại sau nhé!'
                : 'Thử tab khác hoặc quay lại sau.'}
            </p>
          </div>
        )}
      </main>
    </div>
  )
}
