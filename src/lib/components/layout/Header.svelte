<script lang="ts">
	import { browser } from '$app/environment';

	let menuOpen = $state(false);

	function toggleMenu() {
		menuOpen = !menuOpen;
	}
</script>

<header
	class="fixed top-0 left-0 right-0 z-50 bg-white dark:bg-gray-900 border-b border-gray-200 dark:border-gray-800 pt-safe-top"
>
	<div class="flex items-center justify-between h-14 px-4 md:px-6">
		<!-- Logo -->
		<a href="/" class="flex items-center space-x-2">
			<div
				class="w-8 h-8 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-lg flex items-center justify-center"
			>
				<span class="text-white font-bold text-lg">A</span>
			</div>
			<span class="font-bold text-xl text-gray-900 dark:text-white hidden sm:inline">Asocial</span
			>
		</a>

		<!-- Desktop Navigation - Hidden on mobile, visible on md+ -->
		<nav class="hidden md:flex items-center space-x-6">
			<a
				href="/"
				class="text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white transition-colors"
			>
				Home
			</a>
			<a
				href="/about"
				class="text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white transition-colors"
			>
				About
			</a>
		</nav>

		<!-- Mobile Menu Button - Only visible on mobile -->
		<button
			onclick={toggleMenu}
			class="md:hidden p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
			aria-label="Toggle menu"
		>
			<svg
				class="w-6 h-6 text-gray-600 dark:text-gray-300"
				fill="none"
				stroke="currentColor"
				viewBox="0 0 24 24"
			>
				{#if menuOpen}
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M6 18L18 6M6 6l12 12"
					/>
				{:else}
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M4 6h16M4 12h16M4 18h16"
					/>
				{/if}
			</svg>
		</button>
	</div>

	<!-- Mobile Menu Dropdown -->
	{#if menuOpen}
		<div class="md:hidden border-t border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900">
			<nav class="px-4 py-4 space-y-3">
				<a
					href="/"
					class="block px-3 py-2 rounded-lg text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
				>
					Home
				</a>
				<a
					href="/about"
					class="block px-3 py-2 rounded-lg text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
				>
					About
				</a>
			</nav>
		</div>
	{/if}
</header>
