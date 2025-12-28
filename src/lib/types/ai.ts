// AI persona and response types

export interface AIPersona {
  id: string;
  name: string;
  username: string;
  avatar: string;
  bio: string;
  personality: string;
  interests: string[];
  background: string;
  createdAt: Date;
}

export interface AIResponse {
  id: string;
  personaId: string;
  postId: string;
  content: string;
  sentiment: 'positive' | 'neutral' | 'constructive';
  generatedAt: Date;
}
