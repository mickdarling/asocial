import js from '@eslint/js';
import ts from 'typescript-eslint';
import svelte from 'eslint-plugin-svelte';

export default ts.config(
	js.configs.recommended,
	...ts.configs.recommended,
	...svelte.configs['flat/recommended'],
	{
		languageOptions: {
			parserOptions: {
				projectService: true,
				extraFileExtensions: ['.svelte']
			}
		}
	},
	// Disable type-aware linting for test files (not in tsconfig)
	{
		files: ['**/*.test.ts', '**/*.spec.ts'],
		languageOptions: {
			parserOptions: {
				projectService: false,
				project: null
			}
		}
	},
	{
		files: ['**/*.svelte', '**/*.svelte.ts', '**/*.svelte.js'],
		languageOptions: {
			parserOptions: {
				parser: ts.parser
			}
		}
	},
	{
		ignores: [
			'.svelte-kit/',
			'build/',
			'dist/',
			'node_modules/',
			'*.config.js',
			'*.config.ts',
			'vite.config.ts'
		]
	},
	{
		rules: {
			// Allow unused vars with underscore prefix
			'@typescript-eslint/no-unused-vars': [
				'error',
				{ argsIgnorePattern: '^_', varsIgnorePattern: '^_' }
			],
			// Svelte-specific
			'svelte/no-at-html-tags': 'warn'
		}
	}
);
