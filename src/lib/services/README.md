# Services

This directory contains business logic and API interactions.

## Organization

Services should be organized by domain:

- `auth/` - Authentication and user management
- `posts/` - Post creation, retrieval, and management
- `feed/` - Feed generation and personalization
- `ai/` - AI persona and response generation
- `validation/` - Content validation and link checking
- `bridge/` - Social media platform integration

## Guidelines

- Services should be framework-agnostic
- Use dependency injection where appropriate
- Keep services focused on single responsibility
- All external API calls should go through services
