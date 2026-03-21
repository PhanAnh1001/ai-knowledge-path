import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { MemoryRouter } from 'react-router-dom'
import { LoginForm } from '@/components/auth/LoginForm'
import * as authApi from '@/api/auth'

vi.mock('@/api/auth')
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom')
  return { ...actual, useNavigate: () => vi.fn() }
})

function renderWithProviders(ui: React.ReactElement) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } })
  return render(
    <QueryClientProvider client={qc}>
      <MemoryRouter>{ui}</MemoryRouter>
    </QueryClientProvider>,
  )
}

describe('LoginForm', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders email and password fields', () => {
    renderWithProviders(<LoginForm />)
    expect(screen.getByLabelText('Email')).toBeInTheDocument()
    expect(screen.getByLabelText('Mật khẩu')).toBeInTheDocument()
  })

  it('renders submit button', () => {
    renderWithProviders(<LoginForm />)
    expect(screen.getByRole('button', { name: /đăng nhập/i })).toBeInTheDocument()
  })

  it('calls login API with entered credentials', async () => {
    const user = userEvent.setup()
    vi.mocked(authApi.login).mockResolvedValue({
      accessToken: 'token',
      tokenType: 'Bearer',
      expiresIn: 3600,
      userId: 'u1',
      displayName: 'Test',
      explorerType: 'nature',
      ageGroup: 'teen_11_17',
      premium: false,
    })

    renderWithProviders(<LoginForm />)
    await user.type(screen.getByLabelText('Email'), 'test@example.com')
    await user.type(screen.getByLabelText('Mật khẩu'), 'password123')
    await user.click(screen.getByRole('button', { name: /đăng nhập/i }))

    await waitFor(() => {
      expect(authApi.login).toHaveBeenCalled()
      // TanStack Query v5 passes (variables, context) — kiểm tra argument đầu tiên
      const firstCallArg = vi.mocked(authApi.login).mock.calls[0][0]
      expect(firstCallArg).toEqual({
        email: 'test@example.com',
        password: 'password123',
      })
    })
  })

  it('shows error message on failed login', async () => {
    const user = userEvent.setup()
    vi.mocked(authApi.login).mockRejectedValue(new Error('Invalid credentials'))

    renderWithProviders(<LoginForm />)
    await user.type(screen.getByLabelText('Email'), 'bad@example.com')
    await user.type(screen.getByLabelText('Mật khẩu'), 'wrongpass')
    await user.click(screen.getByRole('button', { name: /đăng nhập/i }))

    await waitFor(() => {
      expect(screen.getByRole('alert')).toBeInTheDocument()
    })
  })
})
