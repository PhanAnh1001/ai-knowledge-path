import { useState, type FormEvent } from 'react'
import { useMutation } from '@tanstack/react-query'
import { useNavigate, Link } from 'react-router-dom'
import { register } from '@/api/auth'
import { useAuthStore } from '@/store/authStore'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { clsx } from 'clsx'
import type { AgeGroup, ExplorerType } from '@/types'

// ─── Constants ────────────────────────────────────────────────────────────────

const EXPLORER_OPTIONS: {
  value: ExplorerType
  emoji: string
  label: string
  description: string
}[] = [
  {
    value: 'nature',
    emoji: '🌿',
    label: 'Thiên nhiên',
    description: 'Khoa học, sinh vật, vũ trụ',
  },
  {
    value: 'technology',
    emoji: '⚡',
    label: 'Công nghệ',
    description: 'Máy tính, AI, kỹ thuật',
  },
  {
    value: 'history',
    emoji: '🏛️',
    label: 'Lịch sử',
    description: 'Danh nhân, văn minh, sự kiện',
  },
  {
    value: 'creative',
    emoji: '🎨',
    label: 'Sáng tạo',
    description: 'Nghệ thuật, âm nhạc, triết học',
  },
]

const AGE_OPTIONS: { value: AgeGroup; label: string; sub: string }[] = [
  { value: 'child_8_10',   label: '8–10 tuổi',  sub: 'Tiểu học' },
  { value: 'teen_11_17',   label: '11–17 tuổi', sub: 'Trung học' },
  { value: 'adult_18_plus', label: '18+ tuổi',  sub: 'Người lớn' },
]

// ─── Progress bar ─────────────────────────────────────────────────────────────

function ProgressDots({ total, current }: { total: number; current: number }) {
  return (
    <div className="flex items-center justify-center gap-2">
      {Array.from({ length: total }).map((_, i) => (
        <div
          key={i}
          className={clsx(
            'rounded-full transition-all duration-300',
            i < current
              ? 'h-2 w-2 bg-primary-600'
              : i === current
              ? 'h-2 w-5 bg-primary-600'
              : 'h-2 w-2 bg-gray-200',
          )}
        />
      ))}
    </div>
  )
}

// ─── Step 1: Hook ─────────────────────────────────────────────────────────────

function StepHook({ onNext }: { onNext: () => void }) {
  return (
    <div className="flex flex-col gap-8 text-center">
      <div>
        <p className="text-xs font-semibold uppercase tracking-wider text-primary-500 mb-4">
          Trước khi bắt đầu...
        </p>
        <h2 className="text-2xl font-bold text-gray-900 leading-snug">
          Tại sao bạch tuộc có thể thay đổi màu sắc dù bị mù màu?
        </h2>
        <p className="mt-4 text-gray-500 leading-relaxed">
          Đây là loại câu hỏi bạn sẽ khám phá ở đây — những bí ẩn nhỏ,
          những sự thật bất ngờ, và những kết nối không ngờ tới.
        </p>
      </div>

      <Button className="w-full py-3 text-base" onClick={onNext}>
        Tôi muốn biết! →
      </Button>

      <p className="text-sm text-gray-400">
        Đã có tài khoản?{' '}
        <Link to="/login" className="text-primary-600 hover:underline">
          Đăng nhập
        </Link>
      </p>
    </div>
  )
}

// ─── Step 2: Explorer type ─────────────────────────────────────────────────────

function StepExplorerType({
  value,
  onChange,
  onNext,
}: {
  value: ExplorerType
  onChange: (v: ExplorerType) => void
  onNext: () => void
}) {
  return (
    <div className="flex flex-col gap-6">
      <div className="text-center">
        <h2 className="text-xl font-bold text-gray-900">Bạn là kiểu nhà thám hiểm nào?</h2>
        <p className="mt-2 text-sm text-gray-500">Chọn lĩnh vực bạn tò mò nhất</p>
      </div>

      <div className="grid grid-cols-2 gap-3">
        {EXPLORER_OPTIONS.map((opt) => (
          <button
            key={opt.value}
            onClick={() => onChange(opt.value)}
            className={clsx(
              'flex flex-col items-center gap-2 rounded-xl border p-4 text-center transition-all',
              value === opt.value
                ? 'border-primary-500 bg-primary-50 ring-2 ring-primary-200'
                : 'border-gray-200 bg-white hover:bg-gray-50',
            )}
          >
            <span className="text-3xl">{opt.emoji}</span>
            <span className="text-sm font-semibold text-gray-900">{opt.label}</span>
            <span className="text-xs text-gray-500">{opt.description}</span>
          </button>
        ))}
      </div>

      <Button className="w-full py-3 text-base" onClick={onNext}>
        Tiếp theo →
      </Button>
    </div>
  )
}

// ─── Step 3: Age group ────────────────────────────────────────────────────────

function StepAgeGroup({
  value,
  onChange,
  onNext,
}: {
  value: AgeGroup
  onChange: (v: AgeGroup) => void
  onNext: () => void
}) {
  return (
    <div className="flex flex-col gap-6">
      <div className="text-center">
        <h2 className="text-xl font-bold text-gray-900">Bạn bao nhiêu tuổi?</h2>
        <p className="mt-2 text-sm text-gray-500">
          Giúp chúng tôi điều chỉnh nội dung phù hợp với bạn
        </p>
      </div>

      <div className="flex flex-col gap-3">
        {AGE_OPTIONS.map((opt) => (
          <button
            key={opt.value}
            onClick={() => onChange(opt.value)}
            className={clsx(
              'flex items-center justify-between rounded-xl border px-5 py-4 text-left transition-all',
              value === opt.value
                ? 'border-primary-500 bg-primary-50 ring-2 ring-primary-200'
                : 'border-gray-200 bg-white hover:bg-gray-50',
            )}
          >
            <div>
              <p className="font-semibold text-gray-900">{opt.label}</p>
              <p className="text-xs text-gray-500">{opt.sub}</p>
            </div>
            {value === opt.value && (
              <span className="text-primary-600 font-bold">✓</span>
            )}
          </button>
        ))}
      </div>

      <Button className="w-full py-3 text-base" onClick={onNext}>
        Tiếp theo →
      </Button>
    </div>
  )
}

// ─── Step 4: Profile ──────────────────────────────────────────────────────────

function StepProfile({
  displayName,
  email,
  password,
  onChange,
  onSubmit,
  isLoading,
  error,
}: {
  displayName: string
  email: string
  password: string
  onChange: (field: 'displayName' | 'email' | 'password', value: string) => void
  onSubmit: (e: FormEvent) => void
  isLoading: boolean
  error?: string
}) {
  return (
    <form onSubmit={onSubmit} className="flex flex-col gap-5">
      <div className="text-center">
        <h2 className="text-xl font-bold text-gray-900">Tạo hồ sơ của bạn</h2>
        <p className="mt-2 text-sm text-gray-500">Gần xong rồi!</p>
      </div>

      <Input
        label="Tên hiển thị"
        type="text"
        value={displayName}
        onChange={(e) => onChange('displayName', e.target.value)}
        required
        placeholder="Nhà thám hiểm tò mò"
        autoFocus
      />
      <Input
        label="Email"
        type="email"
        value={email}
        onChange={(e) => onChange('email', e.target.value)}
        required
        placeholder="you@example.com"
      />
      <Input
        label="Mật khẩu"
        type="password"
        value={password}
        onChange={(e) => onChange('password', e.target.value)}
        required
        placeholder="Ít nhất 8 ký tự"
      />

      {error && (
        <p className="text-sm text-red-500" role="alert">
          {error}
        </p>
      )}

      <Button type="submit" isLoading={isLoading} className="w-full py-3 text-base">
        Bắt đầu hành trình ✓
      </Button>
    </form>
  )
}

// ─── Main ─────────────────────────────────────────────────────────────────────

const TOTAL_STEPS = 4

export function OnboardingPage() {
  const navigate = useNavigate()
  const setAuth = useAuthStore((s) => s.setAuth)

  const [step, setStep] = useState(0)
  const [explorerType, setExplorerType] = useState<ExplorerType>('nature')
  const [ageGroup, setAgeGroup] = useState<AgeGroup>('teen_11_17')
  const [displayName, setDisplayName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')

  const mutation = useMutation({
    mutationFn: register,
    onSuccess: (data) => {
      setAuth({
        token: data.accessToken,
        userId: data.userId,
        displayName: data.displayName,
        explorerType: data.explorerType,
        ageGroup: data.ageGroup,
        premium: data.premium,
      })
      navigate('/dashboard')
    },
  })

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault()
    mutation.mutate({ email, displayName, password, explorerType, ageGroup })
  }

  const errorMessage =
    mutation.isError
      ? (mutation.error as { response?: { status?: number } })?.response?.status === 409
        ? 'Email này đã được sử dụng.'
        : 'Đã xảy ra lỗi, vui lòng thử lại.'
      : undefined

  return (
    <div className="flex min-h-screen items-start justify-center bg-gradient-to-br from-primary-50 to-white px-4 pt-16 pb-8">
      <div className="w-full max-w-md">
        {/* Logo */}
        <div className="mb-8 text-center">
          <h1 className="text-2xl font-bold text-gray-900">AI Knowledge Path</h1>
        </div>

        {/* Card */}
        <div className="rounded-2xl bg-white p-8 shadow-lg">
          {/* Progress */}
          <div className="mb-8">
            <ProgressDots total={TOTAL_STEPS} current={step} />
          </div>

          {step === 0 && <StepHook onNext={() => setStep(1)} />}

          {step === 1 && (
            <StepExplorerType
              value={explorerType}
              onChange={setExplorerType}
              onNext={() => setStep(2)}
            />
          )}

          {step === 2 && (
            <StepAgeGroup
              value={ageGroup}
              onChange={setAgeGroup}
              onNext={() => setStep(3)}
            />
          )}

          {step === 3 && (
            <StepProfile
              displayName={displayName}
              email={email}
              password={password}
              onChange={(field, value) => {
                if (field === 'displayName') setDisplayName(value)
                else if (field === 'email') setEmail(value)
                else setPassword(value)
              }}
              onSubmit={handleSubmit}
              isLoading={mutation.isPending}
              error={errorMessage}
            />
          )}

          {/* Back button for steps 2-3 */}
          {step > 0 && step < TOTAL_STEPS && (
            <button
              onClick={() => setStep((s) => s - 1)}
              className="mt-4 w-full text-center text-sm text-gray-400 hover:text-gray-600 transition-colors"
            >
              ← Quay lại
            </button>
          )}
        </div>
      </div>
    </div>
  )
}
