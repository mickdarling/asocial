# Types

This directory contains TypeScript type definitions.

## Organization

Types should be organized by domain:

- `user.ts` - User and authentication types
- `post.ts` - Post and comment types
- `feed.ts` - Feed and timeline types
- `ai.ts` - AI persona and response types
- `api.ts` - API request/response types

## Guidelines

- Use interfaces for object shapes
- Use types for unions and complex types
- Export all types from index.ts for easy imports
- Keep types DRY - reuse common patterns
- Document complex types with JSDoc comments
