import { LoginForm } from '@/components/auth/LoginForm'

export function LoginPage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-primary-50 to-white px-4">
      <div className="w-full max-w-md">
        <div className="mb-8 text-center">
          <h1 className="text-3xl font-bold text-gray-900">AI Wisdom Battle</h1>
          <p className="mt-2 text-gray-500">Khám phá kiến thức không thể cưỡng lại</p>
        </div>
        <div className="rounded-2xl bg-white p-8 shadow-lg">
          <h2 className="mb-6 text-xl font-semibold text-gray-900">Đăng nhập</h2>
          <LoginForm />
        </div>
      </div>
    </div>
  )
}
