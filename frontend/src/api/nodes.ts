import { apiClient } from './client'
import type { KnowledgeNode, NodeMap } from '@/types'

export async function getNodes(domain?: string): Promise<KnowledgeNode[]> {
  const res = await apiClient.get<KnowledgeNode[]>('/nodes', {
    params: domain ? { domain } : undefined,
  })
  return res.data
}

export async function getNodeMap(nodeId: string): Promise<NodeMap> {
  const res = await apiClient.get<NodeMap>(`/nodes/${nodeId}/map`)
  return res.data
}
