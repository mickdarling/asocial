// Feed and timeline types

import type { Post, SharedPost } from './post';
import type { AIConversation } from './ai';

export type FeedItem =
	| { id: string; type: 'post'; timestamp: Date; content: Post }
	| { id: string; type: 'shared_post'; timestamp: Date; content: SharedPost }
	| { id: string; type: 'ai_conversation'; timestamp: Date; content: AIConversation };

export interface Feed {
	items: FeedItem[];
	hasMore: boolean;
	nextCursor?: string;
}
