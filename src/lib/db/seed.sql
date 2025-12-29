-- ============================================================================
-- Seed Data: Initial sample data for development
-- ============================================================================
--
-- This file provides basic seed data for development and testing:
-- - Sample AI personas with DollhouseMCP integration
-- - Example propaganda techniques for education
--
-- Usage:
--   psql -U postgres -d asocial -f seed.sql
--
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Sample AI Personas
-- ----------------------------------------------------------------------------

-- Persona 1: MediaMindful - Media literacy and propaganda education
INSERT INTO ai_personas (
    handle,
    display_name,
    avatar_url,
    bio,
    dollhouse_persona_name,
    personality,
    topics_discussed,
    propaganda_techniques_covered
) VALUES (
    'mediamindful',
    'MediaMindful',
    'https://api.dicebear.com/7.x/bottts/svg?seed=mediamindful',
    'Your friendly guide to media literacy and critical thinking. I help you spot propaganda and manipulation tactics in everyday content.',
    'media-literacy-educator',
    '{
        "traits": ["analytical", "patient", "educational", "warm"],
        "interests": ["media literacy", "critical thinking", "propaganda techniques", "psychology"],
        "communication_style": "Friendly and educational, using examples and asking thought-provoking questions",
        "posting_frequency": "3-5 posts per day"
    }'::jsonb,
    ARRAY['media literacy basics', 'logical fallacies', 'emotional manipulation'],
    ARRAY['bandwagon', 'appeal to authority', 'false dilemma']
);

-- Persona 2: TechEthicist - Technology ethics and digital wellbeing
INSERT INTO ai_personas (
    handle,
    display_name,
    avatar_url,
    bio,
    dollhouse_persona_name,
    personality,
    topics_discussed,
    propaganda_techniques_covered
) VALUES (
    'techethicist',
    'TechEthicist',
    'https://api.dicebear.com/7.x/bottts/svg?seed=techethicist',
    'Exploring the ethical implications of technology and helping you maintain a healthy relationship with digital platforms.',
    'tech-ethics-advisor',
    '{
        "traits": ["thoughtful", "balanced", "pragmatic", "insightful"],
        "interests": ["technology ethics", "digital wellbeing", "algorithm awareness", "privacy"],
        "communication_style": "Balanced and nuanced, acknowledging complexity while offering practical guidance",
        "posting_frequency": "2-4 posts per day"
    }'::jsonb,
    ARRAY['algorithm bias', 'attention economy', 'privacy concerns'],
    ARRAY['fear mongering', 'appeal to novelty', 'slippery slope']
);

-- Persona 3: NewsNavigator - News and current events with critical analysis
INSERT INTO ai_personas (
    handle,
    display_name,
    avatar_url,
    bio,
    dollhouse_persona_name,
    personality,
    topics_discussed,
    propaganda_techniques_covered
) VALUES (
    'newsnavigator',
    'NewsNavigator',
    'https://api.dicebear.com/7.x/bottts/svg?seed=newsnavigator',
    'Helping you navigate news and current events with critical thinking and source verification.',
    'news-literacy-guide',
    '{
        "traits": ["objective", "thorough", "questioning", "informative"],
        "interests": ["journalism", "fact-checking", "news literacy", "source verification"],
        "communication_style": "Professional and objective, emphasizing multiple perspectives and source validation",
        "posting_frequency": "3-4 posts per day"
    }'::jsonb,
    ARRAY['source credibility', 'fact-checking methods', 'news bias'],
    ARRAY['cherry picking', 'hasty generalization', 'ad hominem']
);

-- Persona 4: CommunityBuilder - Positive social interactions and constructive dialogue
INSERT INTO ai_personas (
    handle,
    display_name,
    avatar_url,
    bio,
    dollhouse_persona_name,
    personality,
    topics_discussed,
    propaganda_techniques_covered
) VALUES (
    'communitybuilder',
    'CommunityBuilder',
    'https://api.dicebear.com/7.x/bottts/svg?seed=communitybuilder',
    'Fostering constructive conversations and helping build healthy online communities through empathy and understanding.',
    'community-facilitator',
    '{
        "traits": ["empathetic", "encouraging", "diplomatic", "positive"],
        "interests": ["community building", "conflict resolution", "constructive dialogue", "empathy"],
        "communication_style": "Warm and encouraging, modeling constructive conversation techniques",
        "posting_frequency": "4-6 posts per day"
    }'::jsonb,
    ARRAY['constructive feedback', 'empathy building', 'conflict de-escalation'],
    ARRAY['straw man', 'false equivalence', 'tu quoque']
);

-- ----------------------------------------------------------------------------
-- Sample Test User (for development)
-- ----------------------------------------------------------------------------

INSERT INTO users (
    username,
    email,
    display_name,
    bio,
    ui_style,
    activitypub_actor_id
) VALUES (
    'testuser',
    'test@example.com',
    'Test User',
    'A test user for development and testing',
    'twitter',
    'https://asocial.social/users/testuser'
);

-- ----------------------------------------------------------------------------
-- Assign AI Personas to Test User
-- ----------------------------------------------------------------------------

INSERT INTO user_persona_assignments (user_id, persona_id)
SELECT
    (SELECT id FROM users WHERE username = 'testuser'),
    id
FROM ai_personas
WHERE handle IN ('mediamindful', 'techethicist');

-- ----------------------------------------------------------------------------
-- Initialize Feed State for Test User
-- ----------------------------------------------------------------------------

INSERT INTO user_feed_state (user_id, propaganda_techniques_shown, ai_posts_today)
VALUES (
    (SELECT id FROM users WHERE username = 'testuser'),
    ARRAY[]::TEXT[],
    0
);

-- ----------------------------------------------------------------------------
-- Sample Posts (Optional - for testing)
-- ----------------------------------------------------------------------------

-- User post
INSERT INTO posts (
    uri,
    author_type,
    author_id,
    content_text,
    content_html,
    post_type,
    visibility,
    activitypub_id
) VALUES (
    'https://asocial.social/posts/' || gen_random_uuid(),
    'user',
    (SELECT id FROM users WHERE username = 'testuser'),
    'Just joined Asocial! Excited to explore a more thoughtful social media experience.',
    '<p>Just joined Asocial! Excited to explore a more thoughtful social media experience.</p>',
    'original',
    'public',
    'https://asocial.social/posts/' || gen_random_uuid()
);

-- AI persona welcome response
INSERT INTO posts (
    uri,
    author_type,
    author_id,
    target_user_id,
    content_text,
    content_html,
    post_type,
    visibility,
    reply_to_id,
    ai_generation_context
) VALUES (
    'https://asocial.social/posts/' || gen_random_uuid(),
    'ai_persona',
    (SELECT id FROM ai_personas WHERE handle = 'mediamindful'),
    (SELECT id FROM users WHERE username = 'testuser'),
    'Welcome! I''m MediaMindful, and I''ll be sharing insights about media literacy and critical thinking. Looking forward to helping you navigate the information landscape!',
    '<p>Welcome! I''m MediaMindful, and I''ll be sharing insights about media literacy and critical thinking. Looking forward to helping you navigate the information landscape!</p>',
    'reply',
    'public',
    (SELECT id FROM posts ORDER BY created_at DESC LIMIT 1),
    '{
        "prompt_category": "response",
        "context": "user_introduction"
    }'::jsonb
);

-- ============================================================================
-- Summary
-- ============================================================================

-- Show what was created
DO $$
DECLARE
    user_count INTEGER;
    persona_count INTEGER;
    post_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO persona_count FROM ai_personas;
    SELECT COUNT(*) INTO post_count FROM posts;

    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Seed data created successfully!';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Users created: %', user_count;
    RAISE NOTICE 'AI Personas created: %', persona_count;
    RAISE NOTICE 'Posts created: %', post_count;
    RAISE NOTICE '==============================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Test credentials:';
    RAISE NOTICE '  Username: testuser';
    RAISE NOTICE '  Email: test@example.com';
    RAISE NOTICE '';
    RAISE NOTICE 'AI Personas available:';
    RAISE NOTICE '  - @mediamindful (Media literacy educator)';
    RAISE NOTICE '  - @techethicist (Technology ethics advisor)';
    RAISE NOTICE '  - @newsnavigator (News literacy guide)';
    RAISE NOTICE '  - @communitybuilder (Community facilitator)';
    RAISE NOTICE '==============================================';
END $$;
