import { useMutation } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { startSession } from '@/api/sessions'
import { Button } from '@/components/ui/Button'
import type { KnowledgeNode } from '@/types'
import { clsx } from 'clsx'

const DIFFICULTY_LABEL = ['', 'Dễ', 'Cơ bản', 'Trung bình', 'Nâng cao', 'Thách thức']
const DOMAIN_EMOJI: Record<string, string> = {
  nature: '🌿',
  technology: '⚡',
  history: '🏛️',
  creative: '🎨',
}

interface NodeCardProps {
  node: KnowledgeNode
}

export function NodeCard({ node }: NodeCardProps) {
  const navigate = useNavigate()

  const mutation = useMutation({
    mutationFn: () => startSession({ nodeId: node.id }),
    onSuccess: (data) => {
      navigate(`/session/${data.sessionId}`, { state: { node: data.node } })
    },
  })

  return (
    <div
      className="flex flex-col gap-3 rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-shadow hover:shadow-md"
      data-testid="node-card"
    >
      <div className="flex items-start justify-between gap-2">
        <span className="text-xl">{DOMAIN_EMOJI[node.domain] ?? '📚'}</span>
        <span
          className={clsx(
            'rounded-full px-2 py-0.5 text-xs font-medium',
            node.difficulty <= 2 && 'bg-green-100 text-green-700',
            node.difficulty === 3 && 'bg-yellow-100 text-yellow-700',
            node.difficulty >= 4 && 'bg-red-100 text-red-700',
          )}
        >
          {DIFFICULTY_LABEL[node.difficulty]}
        </span>
      </div>

      <h3 className="font-semibold text-gray-900 leading-snug">{node.title}</h3>

      {node.hook && (
        <p className="text-sm text-gray-500 leading-relaxed line-clamp-2">{node.hook}</p>
      )}

      <div className="flex items-center gap-1 text-xs text-gray-400">
        <span>✨ {node.curiosityScore}/10</span>
      </div>

      <Button
        onClick={() => mutation.mutate()}
        isLoading={mutation.isPending}
        className="mt-auto w-full"
      >
        Bắt đầu khám phá
      </Button>
    </div>
  )
}
