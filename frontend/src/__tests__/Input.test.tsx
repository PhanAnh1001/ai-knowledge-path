import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Input } from '@/components/ui/Input'

describe('Input', () => {
  it('renders label when provided', () => {
    render(<Input label="Email" />)
    expect(screen.getByLabelText('Email')).toBeInTheDocument()
  })

  it('shows error message', () => {
    render(<Input label="Email" error="Email không hợp lệ" />)
    expect(screen.getByText('Email không hợp lệ')).toBeInTheDocument()
  })

  it('updates value on typing', async () => {
    const user = userEvent.setup()
    const onChange = vi.fn()
    render(<Input label="Email" onChange={onChange} />)
    await user.type(screen.getByLabelText('Email'), 'test@example.com')
    expect(onChange).toHaveBeenCalled()
  })

  it('applies error border class when error is provided', () => {
    render(<Input label="Email" error="Lỗi" />)
    expect(screen.getByLabelText('Email')).toHaveClass('border-red-400')
  })
})
