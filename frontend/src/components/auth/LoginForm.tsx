import { useState, type FormEvent } from 'react'
import { useMutation } from '@tanstack/react-query'
import { useNavigate, Link } from 'react-router-dom'
import { login } from '@/api/auth'
import { useAuthStore } from '@/store/authStore'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'

export function LoginForm() {
  const navigate = useNavigate()
  const setAuth = useAuthStore((s) => s.setAuth)
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')

  const mutation = useMutation({
    mutationFn: login,
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
    mutation.mutate({ email, password })
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-4" data-testid="login-form">
      <Input
        label="Email"
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        required
        autoComplete="email"
        placeholder="you@example.com"
      />
      <Input
        label="Mật khẩu"
        type="password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        required
        autoComplete="current-password"
        placeholder="••••••••"
      />

      {mutation.isError && (
        <p className="text-sm text-red-500" role="alert">
          Email hoặc mật khẩu không đúng.
        </p>
      )}

      <Button type="submit" isLoading={mutation.isPending} className="mt-2 w-full">
        Đăng nhập
      </Button>

      <p className="text-center text-sm text-gray-500">
        Chưa có tài khoản?{' '}
        <Link to="/register" className="text-primary-600 hover:underline">
          Đăng ký ngay
        </Link>
      </p>
    </form>
  )
}
