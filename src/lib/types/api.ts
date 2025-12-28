// API request and response types

export interface APIResponse<T> {
	data: T;
	error?: string;
	meta?: {
		pagination?: {
			page: number;
			pageSize: number;
			total: number;
		};
	};
}

export interface APIError {
	message: string;
	code: string;
	details?: Record<string, unknown>;
}
