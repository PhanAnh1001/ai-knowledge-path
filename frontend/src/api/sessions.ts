import { apiClient } from './client'
import type {
  CompleteSessionRequest,
  CompleteSessionResponse,
  Session,
  StartSessionRequest,
} from '@/types'

export async function startSession(data: StartSessionRequest): Promise<Session> {
  const res = await apiClient.post<Session>('/sessions', data)
  return res.data
}

export async function completeSession(
  data: CompleteSessionRequest,
): Promise<CompleteSessionResponse> {
  const res = await apiClient.post<CompleteSessionResponse>('/sessions/complete', data)
  return res.data
}
