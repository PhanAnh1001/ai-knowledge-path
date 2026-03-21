import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useMutation } from '@tanstack/react-query'
import { completeSession } from '@/api/sessions'
import { Button } from '@/components/ui/Button'
import { NodeCard } from '@/components/session/NodeCard'
import type { CompleteSessionResponse } from '@/types'

type Phase = 'learning' | 'completed'

export function SessionPage() {
  const { sessionId } = useParams<{ sessionId: string }>()
  const navigate = useNavigate()
  const [phase, setPhase] = useState<Phase>('learning')
  const [score, setScore] = useState(80)
  const [startTime] = useState(() => Date.now())
  const [result, setResult] = useState<CompleteSessionResponse | null>(null)

  const mutation = useMutation({
    mutationFn: completeSession,
    onSuccess: (data) => {
      setResult(data)
      setPhase('completed')
    },
  })

  const handleComplete = () => {
    if (!sessionId) return
    const durationSeconds = Math.round((Date.now() - startTime) / 1000)
    mutation.mutate({ sessionId, score, durationSeconds })
  }

  if (phase === 'completed' && result) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center bg-gradient-to-br from-primary-50 to-white px-4">
        <div className="w-full max-w-md text-center">
          <div className="mb-4 text-6xl">🎉</div>
          <h2 className="text-2xl font-bold text-gray-900">Session hoàn thành!</h2>
          <p className="mt-2 text-gray-500">
            Điểm thích nghi:{' '}
            <span className="font-bold text-primary-600">
              {result.adaptiveScore.toFixed(1)}
            </span>
          </p>

          {result.nextSuggestions.length > 0 && (
            <div className="mt-8 text-left">
              <h3 className="mb-3 font-semibold text-gray-900">Khám phá tiếp theo</h3>
              <div className="flex flex-col gap-3">
                {result.nextSuggestions.map((node) => (
                  <NodeCard key={node.id} node={node} />
                ))}
              </div>
            </div>
          )}

          <Button
            variant="secondary"
            className="mt-6 w-full"
            onClick={() => navigate('/dashboard')}
          >
            Về trang chủ
          </Button>
        </div>
      </div>
    )
  }

  return (
    <div className="flex min-h-screen flex-col bg-white">
      <header className="border-b px-6 py-4">
        <div className="mx-auto flex max-w-2xl items-center justify-between">
          <Button variant="ghost" onClick={() => navigate('/dashboard')}>
            ← Quay lại
          </Button>
          <span className="text-sm text-gray-500">Session đang diễn ra</span>
        </div>
      </header>

      <main className="mx-auto w-full max-w-2xl flex-1 px-6 py-10">
        <div className="rounded-2xl border border-gray-100 bg-gray-50 p-8 text-center">
          <p className="text-gray-500 text-sm mb-2">Nội dung session đang tải...</p>
          <p className="text-gray-400 text-xs">(Session ID: {sessionId})</p>
        </div>

        {/* Điều chỉnh điểm tự đánh giá */}
        <div className="mt-8">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Bạn hiểu bao nhiêu? ({score}%)
          </label>
          <input
            type="range"
            min={0}
            max={100}
            value={score}
            onChange={(e) => setScore(Number(e.target.value))}
            className="w-full accent-primary-600"
          />
          <div className="flex justify-between text-xs text-gray-400 mt-1">
            <span>Chưa hiểu</span>
            <span>Hiểu hoàn toàn</span>
          </div>
        </div>

        <Button
          className="mt-8 w-full"
          onClick={handleComplete}
          isLoading={mutation.isPending}
        >
          Hoàn thành session
        </Button>
      </main>
    </div>
  )
}
