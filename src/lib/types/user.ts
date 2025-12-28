// User and authentication types

export interface User {
  id: string;
  username: string;
  email: string;
  displayName: string;
  avatar?: string;
  createdAt: Date;
}

export interface UserPreferences {
  theme: 'twitter' | 'facebook' | 'instagram' | 'tiktok';
  notifications: boolean;
  connectedAccounts: ConnectedAccount[];
}

export interface ConnectedAccount {
  platform: 'twitter' | 'facebook' | 'instagram';
  accountId: string;
  accountName: string;
  connectedAt: Date;
}
