-- ============================================================================
-- Migration: 001_initial_schema
-- Description: Initial database schema for Asocial platform
-- Created: 2024-12-28
-- ============================================================================
--
-- This migration creates the core database schema including:
-- - Users and authentication
-- - AI personas (DollhouseMCP integration)
-- - Posts and content
-- - Federation support (ActivityPub, AT Protocol)
-- - Interactions and sharing
-- - Media attachments
-- - Link validation
--
-- ============================================================================

-- Run the complete schema
\i ../schema.sql

-- Migration tracking
CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    applied_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    description TEXT
);

INSERT INTO schema_migrations (version, description)
VALUES ('001_initial_schema', 'Initial database schema with users, posts, AI personas, and federation support');
