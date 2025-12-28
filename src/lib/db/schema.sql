-- ============================================================================
-- Asocial: Anti-Propaganda Social Media Platform
-- PostgreSQL Schema
-- ============================================================================
--
-- Design Principles:
-- - UUID primary keys for distributed systems and federation
-- - JSONB for flexible metadata (personality, generation context)
-- - ENUMs for type safety and performance
-- - Proper indexes on foreign keys and frequently queried columns
-- - Prepared for pgvector extension (semantic search, AI embeddings)
-- - Normalization (3NF) for core entities with strategic denormalization
--
-- Federation Support:
-- - ActivityPub (Mastodon) via activitypub_* fields
-- - AT Protocol (Bluesky) via atproto_* fields
--
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Note: pgvector extension can be added later for semantic search
-- CREATE EXTENSION IF NOT EXISTS "vector";

-- ============================================================================
-- ENUMS (Type Safety)
-- ============================================================================

-- Author type: who created the post
CREATE TYPE author_type AS ENUM ('user', 'ai_persona');

-- Visibility levels for posts
CREATE TYPE visibility_type AS ENUM ('private', 'followers', 'public', 'federated');

-- UI style preferences - different social media aesthetics
CREATE TYPE ui_style_type AS ENUM ('twitter', 'facebook', 'instagram', 'tiktok');

-- Interaction types
CREATE TYPE interaction_type AS ENUM ('like', 'share', 'bookmark', 'report');

-- Post types
CREATE TYPE post_type AS ENUM ('original', 'share', 'quote', 'reply');

-- External platform types
CREATE TYPE platform_type AS ENUM ('twitter', 'mastodon', 'bluesky', 'instagram', 'threads');

-- Media attachment types
CREATE TYPE media_type AS ENUM ('image', 'video', 'audio', 'gif');

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Users: Core user accounts
-- ----------------------------------------------------------------------------
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    bio TEXT,

    -- User preferences
    ui_style ui_style_type NOT NULL DEFAULT 'twitter',

    -- Federation identifiers
    -- ActivityPub: https://asocial.social/users/alice
    activitypub_actor_id TEXT UNIQUE,

    -- AT Protocol: did:plc:abc123
    atproto_did TEXT UNIQUE,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes for users
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_activitypub_actor_id ON users(activitypub_actor_id) WHERE activitypub_actor_id IS NOT NULL;
CREATE INDEX idx_users_atproto_did ON users(atproto_did) WHERE atproto_did IS NOT NULL;

-- ----------------------------------------------------------------------------
-- Connected Accounts: External platform integrations
-- ----------------------------------------------------------------------------
CREATE TABLE connected_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    platform platform_type NOT NULL,
    instance_url TEXT,  -- For federated platforms like Mastodon
    handle VARCHAR(255) NOT NULL,

    -- Encrypted OAuth tokens (application should encrypt before storing)
    access_token TEXT NOT NULL,
    refresh_token TEXT,
    token_expires_at TIMESTAMP WITH TIME ZONE,

    -- Auto-sharing preferences
    auto_share_constructive BOOLEAN NOT NULL DEFAULT false,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Ensure one account per platform per user
    UNIQUE(user_id, platform, handle)
);

-- Indexes for connected accounts
CREATE INDEX idx_connected_accounts_user_id ON connected_accounts(user_id);
CREATE INDEX idx_connected_accounts_platform ON connected_accounts(platform);

-- ----------------------------------------------------------------------------
-- AI Personas: Bot personalities integrated with DollhouseMCP
-- ----------------------------------------------------------------------------
CREATE TABLE ai_personas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    handle VARCHAR(50) NOT NULL UNIQUE,  -- e.g., @MediaMindful
    display_name VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    bio TEXT,

    -- DollhouseMCP Integration
    dollhouse_persona_name VARCHAR(255) NOT NULL,  -- Reference to DollhouseMCP persona
    mcp_server_config JSONB,  -- Optional custom MCP server config

    -- Personality definition (synced from DollhouseMCP)
    -- {
    --   "traits": ["curious", "analytical", "warm"],
    --   "interests": ["media literacy", "technology"],
    --   "communication_style": "casual but informative",
    --   "posting_frequency": "2-4 posts per day"
    -- }
    personality JSONB NOT NULL,

    -- Memory: what has this persona discussed?
    memory_summary TEXT,  -- Compressed summary of posting history
    topics_discussed TEXT[],  -- Array of topics for deduplication
    propaganda_techniques_covered TEXT[],  -- Educational content tracking

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes for AI personas
CREATE INDEX idx_ai_personas_handle ON ai_personas(handle);
CREATE INDEX idx_ai_personas_dollhouse_persona_name ON ai_personas(dollhouse_persona_name);

-- ----------------------------------------------------------------------------
-- User Persona Assignments: Per-user persona relationships
-- ----------------------------------------------------------------------------
CREATE TABLE user_persona_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    persona_id UUID NOT NULL REFERENCES ai_personas(id) ON DELETE CASCADE,

    -- User-specific interaction history
    last_interaction TIMESTAMP WITH TIME ZONE,
    conversation_context TEXT,  -- Summary of their interactions

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Ensure one assignment per user-persona pair
    UNIQUE(user_id, persona_id)
);

-- Indexes for user persona assignments
CREATE INDEX idx_user_persona_assignments_user_id ON user_persona_assignments(user_id);
CREATE INDEX idx_user_persona_assignments_persona_id ON user_persona_assignments(persona_id);

-- ----------------------------------------------------------------------------
-- Posts: Core content (user posts and AI-generated content)
-- ----------------------------------------------------------------------------
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    uri TEXT NOT NULL UNIQUE,  -- Canonical URI for federation

    -- Authorship
    author_type author_type NOT NULL,
    author_id UUID NOT NULL,  -- References users(id) OR ai_personas(id) depending on author_type

    -- For AI posts: which user's feed is this for?
    -- NULL for user posts (visible to followers)
    -- Set for AI posts (only visible to this user)
    target_user_id UUID REFERENCES users(id) ON DELETE CASCADE,

    -- Content
    content_text TEXT NOT NULL,
    content_html TEXT NOT NULL,  -- Rendered with links, mentions

    -- Threading
    reply_to_id UUID REFERENCES posts(id) ON DELETE SET NULL,
    thread_root_id UUID REFERENCES posts(id) ON DELETE SET NULL,

    -- Post metadata
    post_type post_type NOT NULL DEFAULT 'original',
    visibility visibility_type NOT NULL DEFAULT 'public',

    -- Constructiveness scoring (for user posts)
    constructiveness_score FLOAT CHECK (constructiveness_score >= 0 AND constructiveness_score <= 1),
    constructiveness_analysis TEXT,
    eligible_for_bridge BOOLEAN NOT NULL DEFAULT false,

    -- AI-specific metadata
    -- {
    --   "prompt_category": "response" | "original" | "propaganda_education" | "news" | "community",
    --   "propaganda_technique": "bandwagon" (if educational)
    -- }
    ai_generation_context JSONB,

    -- Federation identifiers
    activitypub_id TEXT UNIQUE,  -- e.g., https://asocial.social/posts/abc123
    atproto_uri TEXT UNIQUE,  -- e.g., at://did:plc:abc/app.bsky.feed.post/xyz
    atproto_cid TEXT,  -- Content ID for AT Protocol

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    indexed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()  -- For feed ordering
);

-- Indexes for posts
CREATE INDEX idx_posts_author ON posts(author_type, author_id);
CREATE INDEX idx_posts_target_user_id ON posts(target_user_id) WHERE target_user_id IS NOT NULL;
CREATE INDEX idx_posts_reply_to_id ON posts(reply_to_id) WHERE reply_to_id IS NOT NULL;
CREATE INDEX idx_posts_thread_root_id ON posts(thread_root_id) WHERE thread_root_id IS NOT NULL;
CREATE INDEX idx_posts_visibility ON posts(visibility);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_posts_indexed_at ON posts(indexed_at DESC);
CREATE INDEX idx_posts_eligible_for_bridge ON posts(eligible_for_bridge) WHERE eligible_for_bridge = true;

-- Composite index for feed queries
CREATE INDEX idx_posts_feed_query ON posts(target_user_id, indexed_at DESC) WHERE target_user_id IS NOT NULL;
CREATE INDEX idx_posts_user_timeline ON posts(author_type, author_id, created_at DESC);

-- ----------------------------------------------------------------------------
-- Validated Links: Link metadata and validation
-- ----------------------------------------------------------------------------
CREATE TABLE validated_links (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,

    url TEXT NOT NULL,
    validated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- AI-generated summary of actual content
    content_summary TEXT,
    content_hash VARCHAR(64),  -- SHA-256 hash to detect if content changed

    title TEXT,
    thumbnail_url TEXT,
    is_valid BOOLEAN NOT NULL DEFAULT true,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes for validated links
CREATE INDEX idx_validated_links_post_id ON validated_links(post_id);
CREATE INDEX idx_validated_links_url ON validated_links(url);

-- ----------------------------------------------------------------------------
-- Media Attachments: Images, videos, audio, GIFs
-- ----------------------------------------------------------------------------
CREATE TABLE media_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,

    media_type media_type NOT NULL,
    url TEXT NOT NULL,
    thumbnail_url TEXT,
    alt_text TEXT,
    blurhash VARCHAR(100),  -- For loading placeholders

    -- File metadata
    file_size INTEGER,  -- Bytes
    width INTEGER,
    height INTEGER,
    duration INTEGER,  -- Seconds (for video/audio)

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes for media attachments
CREATE INDEX idx_media_attachments_post_id ON media_attachments(post_id);
CREATE INDEX idx_media_attachments_media_type ON media_attachments(media_type);

-- ----------------------------------------------------------------------------
-- Interactions: Likes, shares, bookmarks, reports
-- ----------------------------------------------------------------------------
CREATE TABLE interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,

    interaction_type interaction_type NOT NULL,

    -- For reports
    report_reason TEXT,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Ensure one interaction per user-post-type combination
    UNIQUE(user_id, post_id, interaction_type)
);

-- Indexes for interactions
CREATE INDEX idx_interactions_user_id ON interactions(user_id);
CREATE INDEX idx_interactions_post_id ON interactions(post_id);
CREATE INDEX idx_interactions_type ON interactions(interaction_type);
CREATE INDEX idx_interactions_created_at ON interactions(created_at DESC);

-- ----------------------------------------------------------------------------
-- Shares: Track post sharing and bridging to external platforms
-- ----------------------------------------------------------------------------
CREATE TABLE shares (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    original_post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    sharing_post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    shared_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- External platform bridges
    -- [{
    --   "platform": "mastodon",
    --   "external_id": "123456",
    --   "url": "https://mastodon.social/@user/123456"
    -- }]
    bridged_to JSONB,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes for shares
CREATE INDEX idx_shares_original_post_id ON shares(original_post_id);
CREATE INDEX idx_shares_sharing_post_id ON shares(sharing_post_id);
CREATE INDEX idx_shares_shared_by_user_id ON shares(shared_by_user_id);

-- ----------------------------------------------------------------------------
-- User Feed State: Track what each user has seen and AI scheduling
-- ----------------------------------------------------------------------------
CREATE TABLE user_feed_state (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,

    -- What has this user seen?
    last_seen_post_id UUID REFERENCES posts(id) ON DELETE SET NULL,
    last_seen_timestamp TIMESTAMP WITH TIME ZONE,

    -- Propaganda education tracking
    propaganda_techniques_shown TEXT[],
    last_propaganda_post TIMESTAMP WITH TIME ZONE,

    -- AI content scheduling
    next_ai_post_scheduled TIMESTAMP WITH TIME ZONE,
    ai_posts_today INTEGER NOT NULL DEFAULT 0,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes for user feed state
CREATE INDEX idx_user_feed_state_next_ai_post ON user_feed_state(next_ai_post_scheduled) WHERE next_ai_post_scheduled IS NOT NULL;

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_connected_accounts_updated_at BEFORE UPDATE ON connected_accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ai_personas_updated_at BEFORE UPDATE ON ai_personas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_feed_state_updated_at BEFORE UPDATE ON user_feed_state
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- VIEWS
-- ============================================================================

-- View for complete post information with author details
CREATE VIEW posts_with_authors AS
SELECT
    p.*,
    CASE
        WHEN p.author_type = 'user' THEN u.username
        WHEN p.author_type = 'ai_persona' THEN ap.handle
    END as author_username,
    CASE
        WHEN p.author_type = 'user' THEN u.display_name
        WHEN p.author_type = 'ai_persona' THEN ap.display_name
    END as author_display_name,
    CASE
        WHEN p.author_type = 'user' THEN u.avatar_url
        WHEN p.author_type = 'ai_persona' THEN ap.avatar_url
    END as author_avatar_url
FROM posts p
LEFT JOIN users u ON p.author_type = 'user' AND p.author_id = u.id
LEFT JOIN ai_personas ap ON p.author_type = 'ai_persona' AND p.author_id = ap.id;

-- View for interaction counts per post
CREATE VIEW post_interaction_counts AS
SELECT
    post_id,
    COUNT(*) FILTER (WHERE interaction_type = 'like') as like_count,
    COUNT(*) FILTER (WHERE interaction_type = 'share') as share_count,
    COUNT(*) FILTER (WHERE interaction_type = 'bookmark') as bookmark_count,
    COUNT(*) FILTER (WHERE interaction_type = 'report') as report_count
FROM interactions
GROUP BY post_id;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE users IS 'Core user accounts with federation support for ActivityPub and AT Protocol';
COMMENT ON TABLE connected_accounts IS 'External platform connections (Twitter, Mastodon, Bluesky, etc.)';
COMMENT ON TABLE ai_personas IS 'AI bot personalities integrated with DollhouseMCP';
COMMENT ON TABLE user_persona_assignments IS 'Per-user AI persona assignments and interaction history';
COMMENT ON TABLE posts IS 'Core content: user posts and AI-generated content';
COMMENT ON TABLE validated_links IS 'Validated link metadata to prevent misinformation';
COMMENT ON TABLE media_attachments IS 'Media files (images, videos, audio, GIFs) attached to posts';
COMMENT ON TABLE interactions IS 'User interactions: likes, shares, bookmarks, reports';
COMMENT ON TABLE shares IS 'Post sharing tracking with external platform bridging';
COMMENT ON TABLE user_feed_state IS 'Per-user feed position and AI content scheduling';

COMMENT ON COLUMN posts.target_user_id IS 'NULL for user posts (visible to followers), set for AI posts (only visible to this user)';
COMMENT ON COLUMN posts.constructiveness_score IS 'Score from 0-1 indicating post quality. Higher scores are eligible for external platform bridging.';
COMMENT ON COLUMN posts.eligible_for_bridge IS 'Whether this post meets quality threshold for sharing to Mastodon/Bluesky';
COMMENT ON COLUMN ai_personas.personality IS 'JSONB: traits, interests, communication_style, posting_frequency';
COMMENT ON COLUMN posts.ai_generation_context IS 'JSONB: prompt_category, propaganda_technique (if educational)';
