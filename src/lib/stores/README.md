# Stores

This directory contains Svelte stores for state management.

## Organization

Stores should be organized by domain:

- `user.ts` - User authentication and profile state
- `feed.ts` - Feed data and pagination
- `posts.ts` - Post data and interactions
- `theme.ts` - UI theme preferences (Twitter/Facebook/Instagram style)
- `ai.ts` - AI persona state and interactions

## Guidelines

- Use writable stores for mutable state
- Use readable stores for computed/derived state
- Use derived stores for combining multiple stores
- Keep stores focused and composable
- Document store shape with TypeScript types
