DROP TRIGGER IF EXISTS trg_user_node_progress_updated_at ON user_node_progress;
DROP TRIGGER IF EXISTS trg_sessions_updated_at ON sessions;
DROP TRIGGER IF EXISTS trg_knowledge_nodes_updated_at ON knowledge_nodes;
DROP TRIGGER IF EXISTS trg_users_updated_at ON users;
DROP FUNCTION IF EXISTS set_updated_at();

DROP TABLE IF EXISTS user_node_progress;
DROP TABLE IF EXISTS sessions;
DROP TABLE IF EXISTS knowledge_nodes;
DROP TABLE IF EXISTS users;
