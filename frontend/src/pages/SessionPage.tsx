import { useState, useEffect } from 'react'
import { useParams, useNavigate, useLocation } from 'react-router-dom'
import { useMutation } from '@tanstack/react-query'
import { completeSession, startSession } from '@/api/sessions'
import { Button } from '@/components/ui/Button'
import type { SessionNodeContent, JourneyStep, CompleteSessionResponse } from '@/types'

type Phase = 'hook' | 'guess' | 'journey' | 'reveal' | 'teach_back' | 'payoff'

const DOMAIN_EMOJI: Record<string, string> = {
  NATURE: '🌿',
  TECHNOLOGY: '⚡',
  HISTORY: '🏛️',
  CREATIVE: '🎨',
}

const DOMAIN_LABEL: Record<string, string> = {
  NATURE: 'Tự nhiên',
  TECHNOLOGY: 'Công nghệ',
  HISTORY: 'Lịch sử',
  CREATIVE: 'Sáng tạo',
}

// Total steps: hook(1) + guess(1) + journey(N) + reveal(1) + teach_back(1) + payoff(1)
function currentStepIndex(phase: Phase, journeyIndex: number, journeyTotal: number): number {
  if (phase === 'hook') return 0
  if (phase === 'guess') return 1
  if (phase === 'journey') return 2 + journeyIndex
  if (phase === 'reveal') return 2 + journeyTotal
  if (phase === 'teach_back') return 2 + journeyTotal + 1
  return 2 + journeyTotal + 2 // payoff
}

// ─── Progress bar ─────────────────────────────────────────────────────────────

function ProgressBar({ pct }: { pct: number }) {
  return (
    <div className="h-1.5 w-full rounded-full bg-gray-100">
      <div
        className="h-1.5 rounded-full bg-primary-500 transition-all duration-500"
        style={{ width: `${pct}%` }}
      />
    </div>
  )
}

// ─── Phase: Hook ─────────────────────────────────────────────────────────────

function HookScreen({ node, onNext }: { node: SessionNodeContent; onNext: () => void }) {
  return (
    <div className="flex flex-col gap-8">
      <div className="text-center">
        <span className="text-5xl">{DOMAIN_EMOJI[node.domain] ?? '📚'}</span>
        <p className="mt-2 text-xs font-semibold uppercase tracking-wider text-gray-400">
          {DOMAIN_LABEL[node.domain] ?? node.domain}
        </p>
        <h1 className="mt-3 text-xl font-bold text-gray-900 leading-snug">{node.title}</h1>
      </div>

      <div className="rounded-2xl bg-primary-50 border border-primary-100 p-6">
        <p className="text-lg text-gray-800 leading-relaxed">{node.hook}</p>
      </div>

      <Button className="w-full py-3 text-base" onClick={onNext}>
        Tôi muốn khám phá! →
      </Button>
    </div>
  )
}

// ─── Phase: Guess ─────────────────────────────────────────────────────────────

function GuessScreen({
  node,
  guess,
  onGuessChange,
  onNext,
}: {
  node: SessionNodeContent
  guess: string
  onGuessChange: (v: string) => void
  onNext: () => void
}) {
  return (
    <div className="flex flex-col gap-6">
      <div>
        <p className="text-xs font-semibold uppercase tracking-wider text-primary-500 mb-2">
          Dự đoán của bạn
        </p>
        <p className="text-lg font-medium text-gray-900 leading-snug">{node.guessPrompt}</p>
      </div>

      <textarea
        className="w-full rounded-xl border border-gray-200 bg-gray-50 p-4 text-gray-800 placeholder-gray-400 focus:border-primary-400 focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary-200 resize-none transition-colors"
        rows={5}
        placeholder="Viết suy nghĩ của bạn — không có câu trả lời sai!"
        value={guess}
        onChange={(e) => onGuessChange(e.target.value)}
        autoFocus
      />

      <Button className="w-full py-3 text-base" onClick={onNext}>
        {guess.trim() ? 'Gửi dự đoán →' : 'Bỏ qua →'}
      </Button>
    </div>
  )
}

// ─── Phase: Journey ───────────────────────────────────────────────────────────

function JourneyScreen({
  step,
  index,
  total,
  isLast,
  onNext,
}: {
  step: JourneyStep
  index: number
  total: number
  isLast: boolean
  onNext: () => void
}) {
  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center gap-3">
        <span className="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full bg-primary-600 text-sm font-bold text-white">
          {step.step}
        </span>
        <p className="text-xs font-semibold uppercase tracking-wider text-gray-400">
          Insight {index + 1} / {total}
        </p>
      </div>

      <div className="rounded-2xl border border-gray-100 bg-white p-6 shadow-sm">
        <p className="text-base text-gray-800 leading-relaxed">{step.text}</p>
      </div>

      <Button className="w-full py-3 text-base" onClick={onNext}>
        {isLast ? 'Xem kết quả →' : 'Tiếp theo →'}
      </Button>
    </div>
  )
}

// ─── Phase: Reveal ────────────────────────────────────────────────────────────

function RevealScreen({
  node,
  guess,
  onNext,
}: {
  node: SessionNodeContent
  guess: string
  onNext: () => void
}) {
  return (
    <div className="flex flex-col gap-6">
      <div>
        <p className="text-xs font-semibold uppercase tracking-wider text-primary-500 mb-2">
          So sánh dự đoán
        </p>
        <p className="text-base text-gray-800 leading-relaxed">{node.revealText}</p>
      </div>

      {guess.trim() && (
        <div className="rounded-xl border border-dashed border-gray-200 bg-gray-50 p-4">
          <p className="text-xs text-gray-400 mb-1">Dự đoán của bạn:</p>
          <p className="text-sm text-gray-700 italic">"{guess}"</p>
        </div>
      )}

      <Button className="w-full py-3 text-base" onClick={onNext}>
        Tôi hiểu rồi! →
      </Button>
    </div>
  )
}

// ─── Phase: Teach Back ────────────────────────────────────────────────────────

function TeachBackScreen({
  node,
  teachBack,
  onTeachBackChange,
  onNext,
  isLoading,
}: {
  node: SessionNodeContent
  teachBack: string
  onTeachBackChange: (v: string) => void
  onNext: () => void
  isLoading: boolean
}) {
  return (
    <div className="flex flex-col gap-6">
      <div>
        <p className="text-xs font-semibold uppercase tracking-wider text-amber-500 mb-2">
          Dạy lại — Feynman Technique
        </p>
        <p className="text-base font-medium text-gray-900 leading-snug">{node.teachBackPrompt}</p>
      </div>

      <textarea
        className="w-full rounded-xl border border-gray-200 bg-gray-50 p-4 text-gray-800 placeholder-gray-400 focus:border-primary-400 focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary-200 resize-none transition-colors"
        rows={6}
        placeholder="Giải thích bằng ngôn ngữ của bạn, như đang nói chuyện với người bạn..."
        value={teachBack}
        onChange={(e) => onTeachBackChange(e.target.value)}
        autoFocus
      />

      <Button className="w-full py-3 text-base" onClick={onNext} isLoading={isLoading}>
        {teachBack.trim() ? 'Hoàn thành session ✓' : 'Bỏ qua →'}
      </Button>
    </div>
  )
}

// ─── Phase: Payoff ────────────────────────────────────────────────────────────

function PayoffScreen({
  node,
  result,
  onGoHome,
  onStartNext,
  isStartingNext,
}: {
  node: SessionNodeContent
  result: CompleteSessionResponse
  onGoHome: () => void
  onStartNext: (nodeId: string) => void
  isStartingNext: boolean
}) {
  return (
    <div className="flex flex-col gap-6">
      <div className="text-center">
        <div className="text-5xl mb-3">🎉</div>
        <h2 className="text-xl font-bold text-gray-900">Session hoàn thành!</h2>
        <p className="mt-1 text-sm text-gray-500">
          Điểm thích nghi:{' '}
          <span className="font-semibold text-primary-600">
            {result.adaptiveScore.toFixed(1)}
          </span>
        </p>
      </div>

      <div className="rounded-2xl bg-amber-50 border border-amber-100 p-5">
        <p className="text-xs font-semibold uppercase tracking-wider text-amber-500 mb-2">
          Insight cuối
        </p>
        <p className="text-base text-gray-800 leading-relaxed">{node.payoffInsight}</p>
      </div>

      {result.nextSuggestions.length > 0 && (
        <div>
          <p className="text-sm font-semibold text-gray-700 mb-3">Khám phá tiếp theo</p>
          <div className="flex flex-col gap-2">
            {result.nextSuggestions.map((next) => (
              <button
                key={next.id}
                onClick={() => onStartNext(next.id)}
                disabled={isStartingNext}
                className="flex items-center gap-3 rounded-xl border border-gray-100 bg-white p-4 text-left shadow-sm transition-shadow hover:shadow-md disabled:opacity-60"
              >
                <span className="text-xl flex-shrink-0">{DOMAIN_EMOJI[next.domain] ?? '📚'}</span>
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-medium text-gray-900 leading-snug line-clamp-2">
                    {next.title}
                  </p>
                  <p className="text-xs text-gray-400 mt-0.5">
                    {DOMAIN_LABEL[next.domain] ?? next.domain}
                  </p>
                </div>
                <span className="text-gray-300 flex-shrink-0">→</span>
              </button>
            ))}
          </div>
        </div>
      )}

      <Button variant="secondary" className="w-full" onClick={onGoHome}>
        Về trang chủ
      </Button>
    </div>
  )
}

// ─── Main ─────────────────────────────────────────────────────────────────────

export function SessionPage() {
  const { sessionId } = useParams<{ sessionId: string }>()
  const navigate = useNavigate()
  const location = useLocation()

  const node = (location.state as { node?: SessionNodeContent } | null)?.node ?? null

  const [phase, setPhase] = useState<Phase>('hook')
  const [journeyIndex, setJourneyIndex] = useState(0)
  const [guess, setGuess] = useState('')
  const [teachBack, setTeachBack] = useState('')
  const [startTime] = useState(() => Date.now())
  const [result, setResult] = useState<CompleteSessionResponse | null>(null)

  useEffect(() => {
    if (!node) navigate('/dashboard', { replace: true })
  }, [node, navigate])

  const completeMutation = useMutation({
    mutationFn: completeSession,
    onSuccess: (data) => {
      setResult(data)
      setPhase('payoff')
    },
  })

  const startNextMutation = useMutation({
    mutationFn: (nodeId: string) => startSession({ nodeId }),
    onSuccess: (data) => {
      navigate(`/session/${data.sessionId}`, { state: { node: data.node } })
    },
  })

  if (!node) return null

  let journeySteps: JourneyStep[] = []
  try {
    journeySteps = JSON.parse(node.journeySteps)
  } catch {
    journeySteps = []
  }

  const totalSteps = 2 + journeySteps.length + 2 + 1
  const currentStep = currentStepIndex(phase, journeyIndex, journeySteps.length)
  const progressPct = totalSteps > 1 ? Math.round((currentStep / (totalSteps - 1)) * 100) : 0

  const handleCompleteSession = () => {
    if (!sessionId) return
    const durationSeconds = Math.round((Date.now() - startTime) / 1000)
    const score = teachBack.trim() ? 90 : 70
    completeMutation.mutate({ sessionId, score, durationSeconds })
  }

  return (
    <div className="flex min-h-screen flex-col bg-white">
      <header className="sticky top-0 z-10 border-b bg-white px-6 py-4">
        <div className="mx-auto max-w-lg">
          <div className="flex items-center justify-between mb-3">
            <button
              onClick={() => navigate('/dashboard')}
              className="text-sm text-gray-400 hover:text-gray-600 transition-colors leading-none"
              aria-label="Thoát session"
            >
              ✕
            </button>
            <span className="text-xs text-gray-400">
              {currentStep + 1} / {totalSteps}
            </span>
          </div>
          <ProgressBar pct={progressPct} />
        </div>
      </header>

      <main className="mx-auto w-full max-w-lg flex-1 px-6 py-8">
        {phase === 'hook' && (
          <HookScreen node={node} onNext={() => setPhase('guess')} />
        )}

        {phase === 'guess' && (
          <GuessScreen
            node={node}
            guess={guess}
            onGuessChange={setGuess}
            onNext={() => { setJourneyIndex(0); setPhase('journey') }}
          />
        )}

        {phase === 'journey' && journeySteps.length > 0 && (
          <JourneyScreen
            step={journeySteps[journeyIndex]}
            index={journeyIndex}
            total={journeySteps.length}
            isLast={journeyIndex === journeySteps.length - 1}
            onNext={() => {
              if (journeyIndex < journeySteps.length - 1) {
                setJourneyIndex((i) => i + 1)
              } else {
                setPhase('reveal')
              }
            }}
          />
        )}

        {phase === 'reveal' && (
          <RevealScreen node={node} guess={guess} onNext={() => setPhase('teach_back')} />
        )}

        {phase === 'teach_back' && (
          <TeachBackScreen
            node={node}
            teachBack={teachBack}
            onTeachBackChange={setTeachBack}
            onNext={handleCompleteSession}
            isLoading={completeMutation.isPending}
          />
        )}

        {phase === 'payoff' && result && (
          <PayoffScreen
            node={node}
            result={result}
            onGoHome={() => navigate('/dashboard')}
            onStartNext={(nodeId) => startNextMutation.mutate(nodeId)}
            isStartingNext={startNextMutation.isPending}
          />
        )}
      </main>
    </div>
  )
}
