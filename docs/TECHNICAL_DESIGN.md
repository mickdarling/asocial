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

```mermaid
flowchart TB
    subgraph Primary["Primary Data Store - PostgreSQL/Supabase"]
        P1[Users, profiles, settings]
        P2[AI Personas - definitions, memory]
        P3[Relationships, follows, blocks]
        P4[Federation state - ActivityPub actors, keys]
    end

    subgraph Feed["Feed/Post Store - TimescaleDB or ScyllaDB"]
        F1[Posts - user and AI generated]
        F2[Time-series optimized]
        F3[Partitioned by user + time]
        F4[Years of history, efficient range queries]
    end

    subgraph Cache["Cache Layer - Redis"]
        C1[Hot feeds - recent posts]
        C2[Session data]
        C3[Rate limiting]
        C4[Real-time pub/sub for live updates]
    end

    subgraph AI["AI Memory Store - pgvector"]
        A1[Persona conversation history]
        A2[Semantic search for context]
        A3[Topics discussed tracking]
        A4[Propaganda technique tracking]
    end

    Primary --> Feed
    Feed --> Cache
    Cache --> AI
```

## Core Data Models

### Entity Relationship Diagram

```mermaid
erDiagram
    USER ||--o{ POST : creates
    USER ||--o{ CONNECTED_ACCOUNT : has
    USER ||--o{ USER_PERSONA_ASSIGNMENT : has
    USER ||--o{ INTERACTION : performs
    USER ||--o{ USER_FEED_STATE : has

    AI_PERSONA ||--o{ POST : creates
    AI_PERSONA ||--o{ USER_PERSONA_ASSIGNMENT : assigned_to

    POST ||--o{ POST : replies_to
    POST ||--o{ VALIDATED_LINK : contains
    POST ||--o{ MEDIA_ATTACHMENT : has
    POST ||--o{ INTERACTION : receives
    POST ||--o{ SHARE : shared_as

    SHARE ||--|| POST : creates_new_post
    SHARE ||--o{ BRIDGED_POST : bridges_to

    USER {
        uuid id PK
        string username
        string email
        string display_name
        enum ui_style
        string activitypub_actor_id
        string atproto_did
    }

    POST {
        uuid id PK
        string uri
        enum author_type
        uuid author_id FK
        uuid target_user_id FK
        string content_text
        uuid reply_to_id FK
        enum visibility
        float constructiveness_score
        boolean eligible_for_bridge
    }

    AI_PERSONA {
        uuid id PK
        string handle
        string display_name
        json personality
        string memory_summary
        array topics_discussed
    }

    INTERACTION {
        uuid id PK
        uuid user_id FK
        uuid post_id FK
        enum type
    }

    SHARE {
        uuid id PK
        uuid original_post_id FK
        uuid sharing_post_id FK
        uuid shared_by_user_id FK
    }
```

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

AI personas leverage the **DollhouseMCP persona specification** for consistency and extensibility. The system acts as an MCP client, connecting to DollhouseMCP server for persona management.

```typescript
interface AIPersona {
  id: UUID
  handle: string                    // e.g., @MediaMindful
  display_name: string
  avatar_url: string
  bio: string

  // DollhouseMCP Integration
  dollhouse_persona_name: string    // Reference to DollhouseMCP persona
  mcp_server_config?: {             // Optional custom MCP server
    server_name: string
    connection_params: object
  }

  // Personality definition (can sync from DollhouseMCP)
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

```mermaid
flowchart LR
    subgraph Asocial["Asocial"]
        Actor[Actor: User]
        Outbox[Outbox: Posts]
        Inbox[Inbox: Replies]
    end

    subgraph Mastodon["Mastodon Instance"]
        MastodonServer[Remote Server]
    end

    Asocial <--> Mastodon
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

```mermaid
flowchart LR
    subgraph Asocial["Asocial"]
        PDS[PDS: User data]
        Repo[Repo: Posts]
    end

    subgraph Bluesky["Bluesky Network"]
        BGS[BGS - Relay]
        AppView[App View]
    end

    Asocial <--> Bluesky
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

```mermaid
flowchart TB
    subgraph CDN["CDN - Cloudflare"]
        Static[Static assets, edge caching]
    end

    subgraph LB["Load Balancer"]
        LoadBalancer[Traffic Distribution]
    end

    subgraph WebTier["Web/API Tier"]
        Web1[Container 1]
        Web2[Container 2]
        Web3[Container 3]
    end

    subgraph Queue["Message Queue - Redis Streams / BullMQ"]
        Jobs[AI generation, federation, validation jobs]
    end

    subgraph Workers["Worker Tier"]
        W1[AI Generation]
        W2[Federation]
        W3[Link Validation]
    end

    subgraph Data["Data Tier"]
        PG[(PostgreSQL)]
        Redis[(Redis Cache)]
        S3[(S3 Media)]
        Vector[(pgvector)]
    end

    CDN --> LB
    LB --> Web1 & Web2 & Web3
    Web1 & Web2 & Web3 --> Queue
    Queue --> W1 & W2 & W3
    W1 & W2 & W3 --> Data
    Web1 & Web2 & Web3 --> Data
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

```mermaid
sequenceDiagram
    participant U as User
    participant API as API Server
    participant DB as PostgreSQL
    participant Q as Job Queue
    participant AI as AI Worker
    participant Fed as Federation Worker
    participant Ext as Mastodon/Bluesky

    U->>API: Submit post
    API->>DB: Store post
    API->>Q: Queue AI response job
    API-->>U: Post confirmed

    Q->>AI: Process AI response
    AI->>DB: Store AI response (linked)
    AI->>API: Push real-time update
    API-->>U: Show AI response

    AI->>Q: Queue constructiveness analysis
    Q->>AI: Analyze constructiveness

    alt Post is constructive
        AI->>Q: Queue federation job
        Q->>Fed: Process federation
        Fed->>Ext: Send to Mastodon/Bluesky
    end
```

### User Loads Feed

```mermaid
sequenceDiagram
    participant U as User
    participant API as API Server
    participant Cache as Redis Cache
    participant DB as PostgreSQL
    participant Client as Client App

    U->>API: Request feed (with cursor)
    API->>Cache: Check hot posts cache

    alt Cache hit
        Cache-->>API: Return cached posts
    else Cache miss
        API->>DB: Query user posts + AI responses + AI persona posts
        DB-->>API: Return posts
        API->>Cache: Update cache
    end

    API->>DB: Check for new federated replies
    DB-->>API: Return replies
    API->>API: Merge and paginate
    API-->>Client: Return feed
    Client->>Client: Render in chosen UI style
```

### AI Persona Generates Educational Post

```mermaid
sequenceDiagram
    participant Sched as Scheduler
    participant DB as PostgreSQL
    participant AI as AI Generator
    participant Val as Link Validator
    participant Feed as Feed Service

    Sched->>DB: Time for propaganda education post?
    DB-->>Sched: Check last post timestamp

    alt Time for new post
        Sched->>DB: What techniques hasn't user seen?
        DB-->>Sched: Return unseen techniques
        Sched->>Sched: Select technique & persona

        Sched->>AI: Generate educational post
        AI->>Val: Validate links
        Val-->>AI: Links confirmed
        AI->>DB: Store post

        opt Generate follow-up conversation
            AI->>AI: Select second persona
            AI->>DB: Store follow-up post
        end

        AI->>DB: Update propaganda_techniques_shown
        AI->>Feed: Add to user's feed
    end
```

## AI System Architecture

### MCP Client Integration

The AI subsystem is an **MCP client** that connects to:

1. **DollhouseMCP Server** - Persona definitions, activation, memory
2. **Optional additional MCP servers** - User-extensible for custom capabilities

```mermaid
flowchart TB
    subgraph AsocialAI["Asocial AI Subsystem"]
        AIWorker[AI Worker]
        MCPClient[MCP Client]
        ContextBuilder[Context Builder]
    end

    subgraph MCPServers["MCP Servers"]
        Dollhouse[DollhouseMCP Server]
        Custom[Custom MCP Servers]
    end

    subgraph LLMProviders["LLM Providers"]
        Anthropic[Anthropic API]
        OpenAI[OpenAI API]
        Google[Google API]
        Local[Local LLM - future]
    end

    AIWorker --> ContextBuilder
    ContextBuilder --> MCPClient
    MCPClient --> Dollhouse
    MCPClient --> Custom
    AIWorker --> LLMProviders
```

### AI Provider Abstraction

Support multiple LLM providers with a unified interface:

```typescript
interface LLMProvider {
  name: 'anthropic' | 'openai' | 'google' | 'local'

  // Model selection per task
  models: {
    fast: string       // Quick tasks (scoring, simple responses)
    balanced: string   // Most tasks (persona responses)
    powerful: string   // Complex analysis
  }

  // API configuration
  apiKey: string
  baseUrl?: string     // For local/custom endpoints
}

// Example configuration
const providers = {
  anthropic: {
    models: {
      fast: 'claude-3-haiku-20240307',
      balanced: 'claude-sonnet-4-20250514',
      powerful: 'claude-opus-4-20250514'
    }
  },
  openai: {
    models: {
      fast: 'gpt-4o-mini',
      balanced: 'gpt-4o',
      powerful: 'gpt-4o'
    }
  }
}
```

### AI Worker Context Requirements

When generating AI responses, the worker needs comprehensive context:

```mermaid
sequenceDiagram
    participant W as AI Worker
    participant CB as Context Builder
    participant DB as Database
    participant MCP as DollhouseMCP
    participant LLM as LLM Provider

    W->>CB: Request context for response

    par Gather Context
        CB->>DB: Get user's recent posts (last N)
        CB->>DB: Get user's profile & preferences
        CB->>DB: Get conversation thread (if reply)
        CB->>DB: Get persona's post history for this user
        CB->>MCP: Get persona definition & active state
    end

    CB->>CB: Build context window
    CB-->>W: Return assembled context

    W->>LLM: Generate response with context
    LLM-->>W: Return response

    W->>DB: Store response
    W->>DB: Update persona memory
```

**Context includes:**

For **responding to user posts**:
- The user's post being responded to
- User's recent post history (tone, topics, patterns)
- User's profile and preferences
- Persona's previous interactions with this user
- Persona's personality definition from DollhouseMCP
- Conversation thread if this is part of a thread

For **independent persona posts**:
- Persona's complete post history (compressed/summarized)
- Topics already covered (avoid repetition)
- Propaganda techniques already discussed (for educational posts)
- Current news/content sources (validated links)
- Time since last post (pacing)

```typescript
interface AIResponseContext {
  // The trigger
  trigger: {
    type: 'user_post' | 'scheduled' | 'conversation_continue'
    source_post?: Post
    thread?: Post[]
  }

  // User context
  user: {
    profile: UserProfile
    recent_posts: Post[]           // Last 10-20 posts
    interaction_history: Post[]    // Previous exchanges with this persona
    preferences: UserPreferences
  }

  // Persona context
  persona: {
    definition: DollhousePersona   // From MCP
    memory_summary: string         // Compressed history
    recent_posts: Post[]           // Last N posts to this user
    topics_covered: string[]
    propaganda_techniques_used: string[]
  }

  // Content context (for original posts)
  content_sources?: {
    validated_links: ValidatedLink[]
    current_events: NewsItem[]
    scheduled_topic?: string       // If propaganda education
  }
}
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
