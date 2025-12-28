// Post and content types

export interface Post {
  id: string;
  authorId: string;
  content: string;
  createdAt: Date;
  updatedAt?: Date;
  isConstructive: boolean;
  isAIGenerated: boolean;
  media?: Media[];
  responses: Response[];
}

export interface Media {
  type: 'image' | 'video';
  url: string;
  alt?: string;
}

export interface Response {
  id: string;
  postId: string;
  authorId: string;
  content: string;
  createdAt: Date;
  isAIGenerated: boolean;
}
