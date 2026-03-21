import { useState, type FormEvent } from 'react'
import { useMutation } from '@tanstack/react-query'
import { useNavigate, Link } from 'react-router-dom'
import { register } from '@/api/auth'
import { useAuthStore } from '@/store/authStore'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import type { AgeGroup, ExplorerType } from '@/types'

const EXPLORER_OPTIONS: { value: ExplorerType; label: string; emoji: string }[] = [
  { value: 'nature', label: 'Thiên nhiên', emoji: '🌿' },
  { value: 'technology', label: 'Công nghệ', emoji: '⚡' },
  { value: 'history', label: 'Lịch sử', emoji: '🏛️' },
  { value: 'creative', label: 'Sáng tạo', emoji: '🎨' },
]

const AGE_OPTIONS: { value: AgeGroup; label: string }[] = [
  { value: 'child_8_10', label: '8–10 tuổi' },
  { value: 'teen_11_17', label: '11–17 tuổi' },
  { value: 'adult_18_plus', label: '18+ tuổi' },
]

export function RegisterForm() {
  const navigate = useNavigate()
  const setAuth = useAuthStore((s) => s.setAuth)
  const [form, setForm] = useState({
    email: '',
    displayName: '',
    password: '',
    explorerType: 'nature' as ExplorerType,
    ageGroup: 'teen_11_17' as AgeGroup,
  })

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

  const set = (field: string) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) =>
    setForm((prev) => ({ ...prev, [field]: e.target.value }))

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault()
    mutation.mutate(form)
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-4" data-testid="register-form">
      <Input
        label="Email"
        type="email"
        value={form.email}
        onChange={set('email')}
        required
        placeholder="you@example.com"
      />
      <Input
        label="Tên hiển thị"
        type="text"
        value={form.displayName}
        onChange={set('displayName')}
        required
        placeholder="Nhà thám hiểm tò mò"
      />
      <Input
        label="Mật khẩu"
        type="password"
        value={form.password}
        onChange={set('password')}
        required
        placeholder="Ít nhất 8 ký tự"
      />

      <div className="flex flex-col gap-1">
        <label className="text-sm font-medium text-gray-700">Kiểu thám hiểm</label>
        <div className="grid grid-cols-2 gap-2">
          {EXPLORER_OPTIONS.map((opt) => (
            <label
              key={opt.value}
              className={`flex cursor-pointer items-center gap-2 rounded-lg border p-3 text-sm transition-colors ${
                form.explorerType === opt.value
                  ? 'border-primary-500 bg-primary-50 text-primary-700'
                  : 'border-gray-200 hover:bg-gray-50'
              }`}
            >
              <input
                type="radio"
                name="explorerType"
                value={opt.value}
                checked={form.explorerType === opt.value}
                onChange={set('explorerType')}
                className="sr-only"
              />
              <span>{opt.emoji}</span>
              <span>{opt.label}</span>
            </label>
          ))}
        </div>
      </div>

      <div className="flex flex-col gap-1">
        <label htmlFor="ageGroup" className="text-sm font-medium text-gray-700">
          Nhóm tuổi
        </label>
        <select
          id="ageGroup"
          value={form.ageGroup}
          onChange={set('ageGroup')}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
        >
          {AGE_OPTIONS.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
      </div>

      {mutation.isError && (
        <p className="text-sm text-red-500" role="alert">
          {(mutation.error as { response?: { status?: number } })?.response?.status === 409
            ? 'Email này đã được sử dụng.'
            : 'Đã xảy ra lỗi, vui lòng thử lại.'}
        </p>
      )}

      <Button type="submit" isLoading={mutation.isPending} className="mt-2 w-full">
        Tạo tài khoản
      </Button>

      <p className="text-center text-sm text-gray-500">
        Đã có tài khoản?{' '}
        <Link to="/login" className="text-primary-600 hover:underline">
          Đăng nhập
        </Link>
      </p>
    </form>
  )
}
