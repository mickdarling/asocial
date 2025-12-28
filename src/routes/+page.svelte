<!-- Welcome Banner -->
<div class="bg-white dark:bg-gray-900 rounded-lg shadow-sm border border-gray-200 dark:border-gray-800 p-6 mb-6">
	<h1 class="text-3xl font-bold text-gray-900 dark:text-white mb-2">Welcome to Asocial</h1>
	<p class="text-lg text-gray-600 dark:text-gray-400">A Constructive Social Network</p>
</div>

<!-- Info Card -->
<div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-6 mb-6">
	<div class="flex items-start space-x-3">
		<svg class="w-6 h-6 text-blue-600 dark:text-blue-400 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
			<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
		</svg>
		<div class="flex-1">
			<h3 class="font-semibold text-gray-900 dark:text-white mb-2">Responsive Layout Demo</h3>
			<p class="text-gray-700 dark:text-gray-300 text-sm">
				This page demonstrates the responsive mobile-first layout. Try resizing your browser or viewing on different devices:
			</p>
		</div>
	</div>
</div>

<!-- Feature Cards -->
<div class="space-y-4 mb-6">
	<h2 class="text-xl font-semibold text-gray-900 dark:text-white">Layout Features</h2>

	<div class="bg-white dark:bg-gray-900 rounded-lg shadow-sm border border-gray-200 dark:border-gray-800 p-5">
		<div class="flex items-center space-x-3 mb-2">
			<div class="w-10 h-10 bg-blue-100 dark:bg-blue-900/30 rounded-lg flex items-center justify-center">
				<svg class="w-6 h-6 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
				</svg>
			</div>
			<h3 class="font-semibold text-gray-900 dark:text-white">Mobile (&lt; 640px)</h3>
		</div>
		<p class="text-gray-600 dark:text-gray-400 text-sm">
			Fixed header at top, scrollable content area, bottom navigation with 5 icons including centered action button
		</p>
	</div>

	<div class="bg-white dark:bg-gray-900 rounded-lg shadow-sm border border-gray-200 dark:border-gray-800 p-5">
		<div class="flex items-center space-x-3 mb-2">
			<div class="w-10 h-10 bg-indigo-100 dark:bg-indigo-900/30 rounded-lg flex items-center justify-center">
				<svg class="w-6 h-6 text-indigo-600 dark:text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
				</svg>
			</div>
			<h3 class="font-semibold text-gray-900 dark:text-white">Tablet (640px - 1024px)</h3>
		</div>
		<p class="text-gray-600 dark:text-gray-400 text-sm">
			Same as mobile layout, optimized spacing and touch targets for tablet interaction
		</p>
	</div>

	<div class="bg-white dark:bg-gray-900 rounded-lg shadow-sm border border-gray-200 dark:border-gray-800 p-5">
		<div class="flex items-center space-x-3 mb-2">
			<div class="w-10 h-10 bg-purple-100 dark:bg-purple-900/30 rounded-lg flex items-center justify-center">
				<svg class="w-6 h-6 text-purple-600 dark:text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
				</svg>
			</div>
			<h3 class="font-semibold text-gray-900 dark:text-white">Desktop (&gt;= 1024px)</h3>
		</div>
		<p class="text-gray-600 dark:text-gray-400 text-sm">
			Fixed header, permanent left sidebar navigation, no bottom bar, content area shifts right to accommodate sidebar
		</p>
	</div>
</div>

<!-- Technical Details -->
<div class="bg-white dark:bg-gray-900 rounded-lg shadow-sm border border-gray-200 dark:border-gray-800 p-6 mb-6">
	<h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-4">Implementation Details</h2>
	<ul class="space-y-2 text-sm text-gray-600 dark:text-gray-400">
		<li class="flex items-start">
			<svg class="w-5 h-5 text-green-500 mr-2 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
				<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
			</svg>
			<span>Mobile-first responsive design with Tailwind CSS breakpoints</span>
		</li>
		<li class="flex items-start">
			<svg class="w-5 h-5 text-green-500 mr-2 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
				<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
			</svg>
			<span>Safe area insets for notched devices (iPhone 15 Pro Max Dynamic Island)</span>
		</li>
		<li class="flex items-start">
			<svg class="w-5 h-5 text-green-500 mr-2 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
				<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
			</svg>
			<span>Dark mode support with class-based theme switching</span>
		</li>
		<li class="flex items-start">
			<svg class="w-5 h-5 text-green-500 mr-2 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
				<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
			</svg>
			<span>Touch targets minimum 44x44px for accessibility</span>
		</li>
		<li class="flex items-start">
			<svg class="w-5 h-5 text-green-500 mr-2 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
				<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
			</svg>
			<span>Atomic design: AppShell → Header, Sidebar, BottomNav, MainContent</span>
		</li>
		<li class="flex items-start">
			<svg class="w-5 h-5 text-green-500 mr-2 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
				<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
			</svg>
			<span>Smooth scrolling with overflow-y-auto on main content</span>
		</li>
	</ul>
</div>

<!-- Demo Content for Scrolling -->
<div class="space-y-4">
	<h2 class="text-xl font-semibold text-gray-900 dark:text-white">Demo Feed</h2>
	{#each Array(5) as _, i}
		<article class="bg-white dark:bg-gray-900 rounded-lg shadow-sm border border-gray-200 dark:border-gray-800 p-5">
			<div class="flex items-start space-x-3">
				<div class="w-10 h-10 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-full flex items-center justify-center text-white font-semibold">
					{String.fromCharCode(65 + i)}
				</div>
				<div class="flex-1">
					<h3 class="font-semibold text-gray-900 dark:text-white">Demo Post {i + 1}</h3>
					<p class="text-sm text-gray-500 dark:text-gray-400 mb-2">Posted 2 hours ago</p>
					<p class="text-gray-700 dark:text-gray-300">
						This is a placeholder post to demonstrate the scrollable feed layout.
						The content area will scroll independently while the header and navigation remain fixed.
					</p>
				</div>
			</div>
		</article>
	{/each}
</div>

<!-- Footer -->
<div class="mt-8 pt-6 border-t border-gray-200 dark:border-gray-800 text-center">
	<p class="text-sm text-gray-500 dark:text-gray-400 italic">
		Because social media should make us better, not bitter.
	</p>
</div>
