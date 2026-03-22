// ── Auth ──────────────────────────────────────────────────────────────────────

export type ExplorerType = 'nature' | 'technology' | 'history' | 'creative'
export type AgeGroup = 'child_8_10' | 'teen_11_17' | 'adult_18_plus'

export interface AuthResponse {
  accessToken: string
  tokenType: string
  expiresIn: number
  userId: string
  displayName: string
  explorerType: ExplorerType
  ageGroup: AgeGroup
  premium: boolean
}

export interface RegisterRequest {
  email: string
  displayName: string
  password: string
  explorerType: ExplorerType
  ageGroup: AgeGroup
}

export interface LoginRequest {
  email: string
  password: string
}

// ── Knowledge Node ────────────────────────────────────────────────────────────

export interface KnowledgeNode {
  id: string
  title: string
  domain: string
  ageGroup: AgeGroup
  difficulty: number
  curiosityScore: number
  published: boolean
  hook?: string
}

export interface JourneyStep {
  step: number
  text: string
}

/** Full node content returned inside SessionStartResponse */
export interface SessionNodeContent {
  id: string
  title: string
  domain: string
  ageGroup: string
  difficulty: number
  curiosityScore: number
  hook: string
  guessPrompt: string
  journeySteps: string   // JSON string: JourneyStep[]
  revealText: string
  teachBackPrompt: string
  payoffInsight: string
}

export interface NodeMap {
  node: KnowledgeNode
  nextNodes: KnowledgeNode[]
  deepDives: KnowledgeNode[]
  crossDomains: KnowledgeNode[]
}

// ── Session ───────────────────────────────────────────────────────────────────

export type SessionStatus = 'IN_PROGRESS' | 'COMPLETED' | 'ABANDONED'

export interface Session {
  sessionId: string
  nodeId: string
  nodeTitle: string
  status: SessionStatus
  startedAt: string
}

export interface SessionStartResponse {
  sessionId: string
  node: SessionNodeContent
}

export interface StartSessionRequest {
  nodeId: string
}

export interface CompleteSessionRequest {
  sessionId: string
  score: number
  durationSeconds: number
}

export interface CompleteSessionResponse {
  sessionId: string
  adaptiveScore: number
  nextSuggestions: KnowledgeNode[]
}

// ── API Error ─────────────────────────────────────────────────────────────────

export interface ApiError {
  error: string
  code?: string
}
