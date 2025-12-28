// Post and content types

export interface Post {
	id: string;
	authorId: string;
	content: string;
	createdAt: Date;
	updatedAt?: Date;
	isConstructive: boolean;
	isAIGenerated: boolean;
	media?: MediaAttachment[];
	responses: PostResponse[];
}

export interface MediaAttachment {
	type: 'image' | 'video';
	url: string;
	alt?: string;
}

export interface PostResponse {
	id: string;
	postId: string;
	authorId: string;
	content: string;
	createdAt: Date;
	isAIGenerated: boolean;
}

export interface SharedPost {
	id: string;
	originalPostId: string;
	sharedById: string;
	sharedAt: Date;
	comment?: string;
	originalPost: Post;
}
