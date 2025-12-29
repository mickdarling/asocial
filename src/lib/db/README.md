# Database Setup Guide

This directory contains the PostgreSQL database schema and setup files for the Asocial platform.

## Prerequisites

- PostgreSQL 15+ (recommended for best JSONB and performance features)
- macOS M4 Max (or any macOS/Linux system)
- Command line access

## Installation on macOS (M4 Max)

### Option 1: Homebrew (Recommended)

```bash
# Install PostgreSQL
brew install postgresql@15

# Start PostgreSQL service
brew services start postgresql@15

# Add to PATH (add to ~/.zshrc or ~/.bash_profile)
echo 'export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify installation
psql --version
```

### Option 2: Postgres.app

1. Download from [https://postgresapp.com/](https://postgresapp.com/)
2. Move to Applications folder
3. Launch Postgres.app
4. Click "Initialize" to create a new server
5. Add to PATH: `sudo mkdir -p /etc/paths.d && echo /Applications/Postgres.app/Contents/Versions/latest/bin | sudo tee /etc/paths.d/postgresapp`

## Database Setup

### 1. Create Database

```bash
# Connect to PostgreSQL
psql postgres

# Create database and user
CREATE DATABASE asocial;
CREATE USER asocial_dev WITH PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE asocial TO asocial_dev;

# Exit psql
\q
```

### 2. Apply Schema

```bash
# Navigate to the project directory
cd /Users/mick/Developer/asocial

# Apply the schema
psql -U asocial_dev -d asocial -f src/lib/db/schema.sql

# Or using the migration
psql -U asocial_dev -d asocial -f src/lib/db/migrations/001_initial_schema.sql
```

### 3. Load Seed Data (Optional)

For development and testing, load sample data:

```bash
psql -U asocial_dev -d asocial -f src/lib/db/seed.sql
```

## Schema Overview

### Core Tables

| Table | Purpose | Key Features |
|-------|---------|--------------|
| `users` | User accounts | Federation support (ActivityPub, AT Protocol) |
| `ai_personas` | AI bot definitions | DollhouseMCP integration, JSONB personality |
| `posts` | Content (user & AI) | Constructiveness scoring, threading, federation |
| `connected_accounts` | External platforms | OAuth tokens, auto-sharing preferences |
| `user_persona_assignments` | User-AI relationships | Per-user interaction tracking |
| `interactions` | Likes, shares, bookmarks, reports | Unique constraint per user-post-type |
| `shares` | Sharing tracking | External platform bridging |
| `validated_links` | Link metadata | AI summaries, content hashing |
| `media_attachments` | Media files | Images, videos, audio, GIFs |
| `user_feed_state` | Feed position & AI scheduling | Propaganda education tracking |

### Database Design Principles

1. **UUID Primary Keys**: For distributed systems and federation compatibility
2. **JSONB for Flexibility**: Personality definitions, metadata, context
3. **ENUMs for Type Safety**: Author types, visibility, platforms, media types
4. **Proper Indexing**: Foreign keys, composite indexes for feed queries
5. **Normalization (3NF)**: Clean relational design with strategic denormalization
6. **Federation-Ready**: ActivityPub and AT Protocol support built-in
7. **AI-First**: Designed for per-user AI content and DollhouseMCP integration

### Key Design Decisions

#### Per-User AI Content

Posts have an optional `target_user_id`:
- `NULL` for user posts → visible to followers
- Set for AI posts → only visible to that specific user

This enables personalized AI content without data duplication.

#### Polymorphic Authors

Posts use `author_type` + `author_id`:
- `author_type = 'user'` → `author_id` references `users.id`
- `author_type = 'ai_persona'` → `author_id` references `ai_personas.id`

No foreign key constraint (by design) to support polymorphism.

#### Constructiveness Scoring

User posts are scored (0-1) for quality:
- Score ≥ threshold → `eligible_for_bridge = true`
- Eligible posts can be shared to Mastodon/Bluesky
- AI posts are not scored (always internal)

## Environment Configuration

Create a `.env` file in your project root:

```env
# Database
DATABASE_URL=postgresql://asocial_dev:your_secure_password@localhost:5432/asocial

# Alternative format for ORMs
DB_HOST=localhost
DB_PORT=5432
DB_NAME=asocial
DB_USER=asocial_dev
DB_PASSWORD=your_secure_password

# Connection pool settings
DB_POOL_MIN=2
DB_POOL_MAX=10
```

## Useful Commands

### Database Operations

```bash
# Connect to database
psql -U asocial_dev -d asocial

# List all tables
\dt

# Describe a table
\d users

# List all indexes
\di

# View table with data
SELECT * FROM ai_personas;

# Check migration status
SELECT * FROM schema_migrations ORDER BY applied_at;

# Backup database
pg_dump -U asocial_dev asocial > asocial_backup_$(date +%Y%m%d).sql

# Restore database
psql -U asocial_dev -d asocial < asocial_backup_20241228.sql

# Drop and recreate database (CAUTION!)
dropdb asocial
createdb asocial
psql -U asocial_dev -d asocial -f src/lib/db/schema.sql
```

### Performance Tuning

```sql
-- Check index usage
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- Check table sizes
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Analyze query performance
EXPLAIN ANALYZE
SELECT * FROM posts_with_authors
WHERE target_user_id = 'some-uuid'
ORDER BY indexed_at DESC
LIMIT 20;
```

## Future Extensions

### pgvector for Semantic Search

When ready to add AI embeddings and semantic search:

```sql
-- Install extension
CREATE EXTENSION vector;

-- Add embedding column to posts
ALTER TABLE posts
ADD COLUMN embedding vector(1536);  -- OpenAI ada-002 dimensions

-- Create index for similarity search
CREATE INDEX ON posts USING ivfflat (embedding vector_cosine_ops);

-- Add to AI personas for memory
ALTER TABLE ai_personas
ADD COLUMN memory_embeddings vector(1536)[];
```

### PostGIS for Location Features

If adding location-based features:

```sql
-- Install extension
CREATE EXTENSION postgis;

-- Add location to posts
ALTER TABLE posts
ADD COLUMN location geography(POINT, 4326);

-- Create spatial index
CREATE INDEX idx_posts_location ON posts USING GIST(location);
```

## Troubleshooting

### Connection Issues

```bash
# Check if PostgreSQL is running
brew services list | grep postgresql

# Check what's listening on port 5432
lsof -i :5432

# Restart PostgreSQL
brew services restart postgresql@15
```

### Permission Issues

```sql
-- Grant all privileges to user
GRANT ALL PRIVILEGES ON DATABASE asocial TO asocial_dev;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO asocial_dev;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO asocial_dev;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO asocial_dev;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO asocial_dev;
```

### Schema Reload

If you need to completely reset the database:

```bash
# WARNING: This will DELETE ALL DATA!
psql -U asocial_dev -d asocial -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
psql -U asocial_dev -d asocial -f src/lib/db/schema.sql
psql -U asocial_dev -d asocial -f src/lib/db/seed.sql
```

## Next Steps

1. Install PostgreSQL on your development machine
2. Create the `asocial` database
3. Apply the schema using `schema.sql`
4. Load seed data for testing
5. Configure environment variables
6. Connect from your application

## Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PostgreSQL on macOS](https://www.postgresql.org/download/macosx/)
- [JSONB Best Practices](https://www.postgresql.org/docs/current/datatype-json.html)
- [ActivityPub Specification](https://www.w3.org/TR/activitypub/)
- [AT Protocol Specification](https://atproto.com/)
- [DollhouseMCP Documentation](https://github.com/anthropics/dollhousemcp)

## Migration Strategy

This is the initial schema (`001_initial_schema`). Future changes should:

1. Create new migration files: `002_description.sql`, `003_description.sql`, etc.
2. Use `ALTER TABLE` for modifications
3. Never modify existing migrations
4. Track in `schema_migrations` table
5. Include rollback instructions in comments

Example future migration:

```sql
-- Migration: 002_add_user_preferences
-- Description: Add user notification preferences

ALTER TABLE users
ADD COLUMN notification_preferences JSONB DEFAULT '{
  "email": true,
  "push": true,
  "ai_responses": true
}'::jsonb;

INSERT INTO schema_migrations (version, description)
VALUES ('002_add_user_preferences', 'Add notification preferences to users');

-- Rollback:
-- ALTER TABLE users DROP COLUMN notification_preferences;
```

## Contact

For questions or issues with the database setup, please open an issue on GitHub.
