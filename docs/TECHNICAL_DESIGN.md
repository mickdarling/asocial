# Technical Design: Data Model & Architecture

## Constraints

- **Hosted** - Cloud-based, not local
- **Mobile-first** - Must work on phones, tablets, desktop
- **Federated** - Compatible with ActivityPub (Mastodon) and AT Protocol (Bluesky)
- **Persistent History** - Years of feed data per user
- **Per-User AI Content** - Unique AI personas/content per user feed

## Data Model Options

### Database Choices

| Option | Pros | Cons | Good For |
|--------|------|------|----------|
| **PostgreSQL** | Battle-tested, JSONB flexibility, what Mastodon uses, great tooling | Scaling writes can be tricky | Core relational data, ActivityPub compatibility |
| **Supabase** | PostgreSQL + real-time + auth + edge functions, fast MVP | Vendor lock-in, cost at scale | Rapid development, real-time feeds |
| **PlanetScale** | Serverless MySQL, horizontal scaling, branching | MySQL not Postgres, no foreign keys | High-scale writes, serverless |
| **CockroachDB** | Distributed Postgres-compatible, global scale | Complexity, cost | Multi-region, high availability |
| **MongoDB** | Flexible schema, document model fits posts | Weaker consistency, joins are awkward | Rapid prototyping, variable schemas |
| **ScyllaDB/Cassandra** | Extreme write throughput, time-series friendly | Complex operations, eventual consistency | Feed storage at massive scale |

### Recommended: Hybrid Approach

```
┌─────────────────────────────────────────────────────────────┐
│                     Primary Data Store                       │
│                      PostgreSQL/Supabase                     │
│  - Users, profiles, settings                                │
│  - AI Personas (definitions, memory)                        │
│  - Relationships, follows, blocks                           │
│  - Federation state (ActivityPub actors, keys)              │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                      Feed/Post Store                         │
│                   TimescaleDB or ScyllaDB                    │
│  - Posts (user and AI generated)                            │
│  - Time-series optimized                                    │
│  - Partitioned by user + time                               │
│  - Years of history, efficient range queries                │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                        Cache Layer                           │
│                          Redis                               │
│  - Hot feeds (recent posts)                                 │
│  - Session data                                             │
│  - Rate limiting                                            │
│  - Real-time pub/sub for live updates                       │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                      AI Memory Store                         │
│                    Vector DB (pgvector)                      │
│  - Persona conversation history                             │
│  - Semantic search for context                              │
│  - What topics has this persona discussed?                  │
│  - Propaganda technique tracking                            │
└─────────────────────────────────────────────────────────────┘
```

## Core Data Models

### User
```typescript
interface User {
  id: UUID
  username: string
  email: string
  display_name: string
  avatar_url: string
  bio: string

  // Preferences
  ui_style: 'twitter' | 'facebook' | 'instagram' | 'tiktok'

  // Federation
  activitypub_actor_id: string      // e.g., https://asocial.social/users/alice
  atproto_did: string               // e.g., did:plc:abc123

  // Connected external accounts
  connected_accounts: ConnectedAccount[]

  created_at: timestamp
  updated_at: timestamp
}

interface ConnectedAccount {
  platform: 'twitter' | 'mastodon' | 'bluesky' | 'instagram' | 'threads'
  instance_url?: string             // For Mastodon instances
  handle: string
  access_token: encrypted_string
  auto_share_constructive: boolean  // Auto-share qualifying posts
}
```

### Post
```typescript
interface Post {
  id: UUID
  uri: string                       // Canonical URI for federation

  // Authorship
  author_type: 'user' | 'ai_persona'
  author_id: UUID                   // User ID or AI Persona ID

  // For AI posts - which user's feed is this for?
  // NULL for user posts (visible to all who follow)
  // Set for AI posts (only visible to this user)
  target_user_id: UUID | null

  // Content
  content_text: string
  content_html: string              // Rendered with links, mentions
  media_attachments: MediaAttachment[]
  links: ValidatedLink[]

  // Threading
  reply_to_id: UUID | null
  thread_root_id: UUID | null

  // Metadata
  post_type: 'original' | 'share' | 'quote' | 'reply'
  visibility: 'private' | 'followers' | 'public' | 'federated'

  // Constructiveness (for user posts)
  constructiveness_score: float | null
  constructiveness_analysis: string | null
  eligible_for_bridge: boolean

  // AI-specific metadata
  ai_generation_context?: {
    prompt_category: 'response' | 'original' | 'propaganda_education' | 'news' | 'community'
    propaganda_technique?: string   // If educational post
  }

  // Federation
  activitypub_id: string | null
  atproto_uri: string | null
  atproto_cid: string | null

  created_at: timestamp
  updated_at: timestamp
  indexed_at: timestamp             // For feed ordering
}

interface ValidatedLink {
  url: string
  validated_at: timestamp
  content_summary: string           // AI-generated summary of actual content
  content_hash: string              // To detect if content changed
  title: string
  thumbnail_url: string | null
  is_valid: boolean
}

interface MediaAttachment {
  id: UUID
  type: 'image' | 'video' | 'audio' | 'gif'
  url: string
  thumbnail_url: string
  alt_text: string
  blurhash: string                  // For loading placeholders
}
```

### AI Persona
```typescript
interface AIPersona {
  id: UUID
  handle: string                    // e.g., @MediaMindful
  display_name: string
  avatar_url: string
  bio: string

  // Personality definition
  personality: {
    traits: string[]                // ["curious", "analytical", "warm"]
    interests: string[]             // ["media literacy", "technology", "cooking"]
    communication_style: string     // "casual but informative"
    posting_frequency: string       // "2-4 posts per day"
  }

  // Memory (what have they discussed?)
  memory_summary: string            // Compressed summary of posting history
  topics_discussed: string[]        // For deduplication
  propaganda_techniques_covered: string[]

  created_at: timestamp
}

// Per-user persona assignment
interface UserPersonaAssignment {
  user_id: UUID
  persona_id: UUID

  // This user's specific history with this persona
  last_interaction: timestamp
  conversation_context: string      // Summary of their interactions

  created_at: timestamp
}
```

### Feed State
```typescript
interface UserFeedState {
  user_id: UUID

  // What has this user seen?
  last_seen_post_id: UUID
  last_seen_timestamp: timestamp

  // Propaganda education tracking
  propaganda_techniques_shown: string[]
  last_propaganda_post: timestamp

  // AI content scheduling
  next_ai_post_scheduled: timestamp
  ai_posts_today: number
}
```

### Interactions
```typescript
interface Interaction {
  id: UUID
  user_id: UUID
  post_id: UUID
  type: 'like' | 'share' | 'bookmark' | 'report'
  created_at: timestamp
}

// Shares create new posts, but we track the relationship
interface Share {
  id: UUID
  original_post_id: UUID
  sharing_post_id: UUID             // The new post created by sharing
  shared_by_user_id: UUID

  // Did this go to external platforms?
  bridged_to: {
    platform: string
    external_id: string
    url: string
  }[]

  created_at: timestamp
}
```

## Federation Design

### ActivityPub (Mastodon, etc.)

Asocial acts as an ActivityPub server:

```
┌─────────────────┐         ┌─────────────────┐
│    Asocial      │ ◄─────► │    Mastodon     │
│                 │         │    Instance     │
│  Actor: User    │         │                 │
│  Outbox: Posts  │         │                 │
│  Inbox: Replies │         │                 │
└─────────────────┘         └─────────────────┘
```

**Outbound (Push):**
- User posts marked constructive → Create ActivityPub Note → Deliver to followers
- Shares → Announce activity

**Inbound (Pull/Receive):**
- Replies from Mastodon users → Store as posts, show in user's feed
- Follows → Track remote followers
- Likes/Boosts → Track engagement

**Key consideration:** AI persona posts are NOT federated. Only real user constructive content goes out.

### AT Protocol (Bluesky)

```
┌─────────────────┐         ┌─────────────────┐
│    Asocial      │ ◄─────► │    Bluesky      │
│                 │         │    Network      │
│  PDS: User data │         │                 │
│  Repo: Posts    │         │                 │
└─────────────────┘         └─────────────────┘
```

**Options:**
1. Run as a PDS (Personal Data Server) - users' data lives on Asocial
2. Connect to users' existing Bluesky accounts via OAuth

**Outbound:**
- Constructive posts → Create record in user's repo → Federate via BGS

**Inbound:**
- Subscribe to firehose for replies to Asocial users
- Pull user's follows/followers from their PDS

## Mobile Strategy

### Option 1: Progressive Web App (PWA) - Recommended for MVP

**Pros:**
- Single codebase (web)
- Works on all devices
- Push notifications (with service worker)
- Offline support
- No app store approval needed
- Instant updates

**Cons:**
- Slightly less native feel
- iOS has some PWA limitations
- No access to some native APIs

**Tech stack:**
- Next.js or SvelteKit
- Tailwind CSS
- Service workers for offline
- Web Push for notifications

### Option 2: React Native / Expo

**Pros:**
- Native feel
- Full device API access
- Better performance
- App store presence

**Cons:**
- Two builds (iOS/Android)
- App store review process
- More complex deployment

### Option 3: Hybrid (PWA + Native wrapper)

Start with PWA, wrap in Capacitor/Tauri for app stores later.

## Hosting Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                           CDN (Cloudflare)                          │
│                     Static assets, edge caching                     │
└─────────────────────────────────────────────────────────────────────┘
                                    │
┌─────────────────────────────────────────────────────────────────────┐
│                        Load Balancer                                 │
└─────────────────────────────────────────────────────────────────────┘
            │                       │                       │
┌───────────────────┐   ┌───────────────────┐   ┌───────────────────┐
│   Web/API Tier    │   │   Web/API Tier    │   │   Web/API Tier    │
│   (Containers)    │   │   (Containers)    │   │   (Containers)    │
└───────────────────┘   └───────────────────┘   └───────────────────┘
            │                       │                       │
┌─────────────────────────────────────────────────────────────────────┐
│                         Message Queue                                │
│                    (Redis Streams / BullMQ)                         │
│           AI generation, federation, validation jobs                 │
└─────────────────────────────────────────────────────────────────────┘
            │                       │                       │
┌───────────────────┐   ┌───────────────────┐   ┌───────────────────┐
│   Worker Tier     │   │   Worker Tier     │   │   Worker Tier     │
│  AI Generation    │   │   Federation      │   │  Link Validation  │
└───────────────────┘   └───────────────────┘   └───────────────────┘
            │                       │                       │
┌─────────────────────────────────────────────────────────────────────┐
│                        Data Tier                                     │
│   PostgreSQL (primary) │ Redis (cache) │ S3 (media) │ pgvector     │
└─────────────────────────────────────────────────────────────────────┘
```

### Platform Options

| Platform | Pros | Cons | Cost |
|----------|------|------|------|
| **Railway** | Easy deploy, good DX, Postgres included | Smaller scale | $$ |
| **Render** | Simple, good free tier, managed Postgres | Can be slow | $ |
| **Fly.io** | Edge deployment, good for real-time | More ops work | $$ |
| **Vercel + Supabase** | Great DX, serverless, real-time | Vendor lock-in | $-$$$ |
| **AWS** | Full control, all services | Complex, ops heavy | $$-$$$$ |
| **DigitalOcean App Platform** | Simple, good Postgres | Limited scaling | $$ |

### Recommended Stack for MVP

```
Frontend:       Next.js 14+ (App Router)
Styling:        Tailwind CSS
State:          Zustand or Jotai
Real-time:      Supabase Realtime or Socket.io

Backend:        Next.js API routes + separate worker service
Database:       Supabase (PostgreSQL + pgvector + auth + realtime)
Cache:          Upstash Redis (serverless)
Queue:          Upstash QStash or BullMQ
Media:          Cloudflare R2 or S3

AI:             Anthropic Claude API (for responses, content analysis)
                OpenAI for embeddings (pgvector)

Hosting:        Vercel (web) + Railway (workers)
CDN:            Cloudflare

Federation:     Custom ActivityPub implementation
                @atproto/api for Bluesky
```

## Data Flow Examples

### User Posts Something

```
1. User submits post
2. Store in PostgreSQL
3. Queue AI response generation
4. Worker generates constructive response using Claude
5. Store AI response post (linked to user post)
6. Push real-time update to user's feed
7. Queue constructiveness analysis
8. If constructive: queue for federation/bridge
9. Federation worker sends to Mastodon/Bluesky
```

### User Loads Feed

```
1. Request feed with cursor (timestamp)
2. Query: user's posts + AI responses + AI persona posts for this user
3. Check Redis cache for hot posts
4. Merge with any new federated replies
5. Return paginated results
6. Client renders in chosen UI style
```

### AI Persona Generates Educational Post

```
1. Scheduler checks: time for propaganda education post?
2. Query: what techniques hasn't this user seen?
3. Select technique, select persona
4. Generate post with validated links
5. Optionally generate follow-up from second persona
6. Store posts, update user's propaganda_techniques_shown
7. Posts appear in user's feed naturally
```

## Scaling Considerations

**Per-user AI content is expensive.** Strategies:

1. **Batch generation** - Pre-generate some AI content, personalize on delivery
2. **Shared educational content** - Propaganda posts can be same content, different timing
3. **Tiered AI** - Faster/cheaper models for routine responses, Claude for complex
4. **Caching** - Cache AI response patterns, link validations

**Feed queries at scale:**

1. **Fan-out on write** - Pre-compute feeds (expensive writes, cheap reads)
2. **Fan-out on read** - Compute feeds on demand (cheap writes, expensive reads)
3. **Hybrid** - Pre-compute for active users, on-demand for others

## Next Steps

1. [ ] Finalize database schema
2. [ ] Set up Supabase project
3. [ ] Implement core post/feed APIs
4. [ ] Build basic web UI (pick one style first)
5. [ ] Implement AI response generation
6. [ ] Add ActivityPub federation
7. [ ] Add Bluesky integration
8. [ ] Build out AI persona system
9. [ ] Add propaganda education content
10. [ ] PWA features (offline, push notifications)
