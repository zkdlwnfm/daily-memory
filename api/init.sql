CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE memory_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(128) NOT NULL,
    memory_id VARCHAR(128) NOT NULL,
    embedding vector(1536) NOT NULL,
    text_hash VARCHAR(64),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, memory_id)
);
CREATE INDEX idx_memory_embeddings_user_id ON memory_embeddings(user_id);
CREATE INDEX idx_memory_embeddings_vector ON memory_embeddings USING hnsw (embedding vector_cosine_ops);

CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid VARCHAR(128) UNIQUE NOT NULL,
    email VARCHAR(255),
    is_premium BOOLEAN NOT NULL DEFAULT FALSE,
    daily_ai_count INTEGER NOT NULL DEFAULT 0,
    daily_embed_count INTEGER NOT NULL DEFAULT 0,
    daily_image_count INTEGER NOT NULL DEFAULT 0,
    daily_search_count INTEGER NOT NULL DEFAULT 0,
    count_reset_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE api_usage_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(128) NOT NULL,
    endpoint VARCHAR(100) NOT NULL,
    tokens_used INTEGER,
    model VARCHAR(50),
    latency_ms INTEGER,
    status VARCHAR(20),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_api_usage_logs_user_date ON api_usage_logs(user_id, created_at);
