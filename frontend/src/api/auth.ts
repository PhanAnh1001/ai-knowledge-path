import { apiClient } from './client'
import type { AuthResponse, LoginRequest, RegisterRequest, UserProfile } from '@/types'

export async function register(data: RegisterRequest): Promise<AuthResponse> {
  const res = await apiClient.post<AuthResponse>('/auth/register', data)
  return res.data
}

export async function login(data: LoginRequest): Promise<AuthResponse> {
  const res = await apiClient.post<AuthResponse>('/auth/login', data)
  return res.data
}

export async function getMe(): Promise<UserProfile> {
  const res = await apiClient.get<UserProfile>('/auth/me')
  return res.data
}

export async function logout(): Promise<void> {
  await apiClient.post('/auth/logout')
}
