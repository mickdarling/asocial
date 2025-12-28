// Feed and timeline types

export interface FeedItem {
	id: string;
	type: 'post' | 'shared_post' | 'ai_conversation';
	timestamp: Date;
	content: unknown; // Will be Post, SharedPost, or AIConversation
}

export interface Feed {
	items: FeedItem[];
	hasMore: boolean;
	nextCursor?: string;
}
