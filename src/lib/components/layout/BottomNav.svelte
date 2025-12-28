<script lang="ts">
	import { page } from '$app/stores';

	const navItems = [
		{
			name: 'Home',
			href: '/',
			icon: 'M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6'
		},
		{
			name: 'Search',
			href: '/search',
			icon: 'M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z'
		},
		{
			name: 'Post',
			href: '/post',
			icon: 'M12 4v16m8-8H4',
			isAction: true
		},
		{
			name: 'Notifications',
			href: '/notifications',
			icon: 'M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9'
		},
		{
			name: 'Profile',
			href: '/profile',
			icon: 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z'
		}
	];
</script>

<!-- Bottom Navigation - Only visible on mobile (<md) -->
<nav
	class="md:hidden fixed bottom-0 left-0 right-0 z-40 bg-white dark:bg-gray-900 border-t border-gray-200 dark:border-gray-800 pb-safe-bottom"
>
	<div class="grid grid-cols-5 h-16">
		{#each navItems as item}
			{@const isActive = $page.url.pathname === item.href}
			<a
				href={item.href}
				class="flex flex-col items-center justify-center space-y-1 transition-colors min-h-[44px]
					{isActive
					? 'text-blue-600 dark:text-blue-400'
					: 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200'}
					{item.isAction ? 'relative' : ''}"
				aria-label={item.name}
			>
				{#if item.isAction}
					<!-- Special styling for the Post action button -->
					<div
						class="absolute -top-6 w-14 h-14 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-full flex items-center justify-center shadow-lg"
					>
						<svg
							class="w-7 h-7 text-white"
							fill="none"
							stroke="currentColor"
							viewBox="0 0 24 24"
							stroke-width="2.5"
						>
							<path stroke-linecap="round" stroke-linejoin="round" d={item.icon} />
						</svg>
					</div>
					<span class="text-xs font-medium mt-5">{item.name}</span>
				{:else}
					<svg
						class="w-6 h-6"
						fill="none"
						stroke="currentColor"
						viewBox="0 0 24 24"
						stroke-width={isActive ? '2' : '1.5'}
					>
						<path stroke-linecap="round" stroke-linejoin="round" d={item.icon} />
					</svg>
					<span class="text-xs font-medium">{item.name}</span>
				{/if}
			</a>
		{/each}
	</div>
</nav>
