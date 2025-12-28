<script lang="ts">
	import Header from './Header.svelte';
	import BottomNav from './BottomNav.svelte';
	import Sidebar from './Sidebar.svelte';
	import MainContent from './MainContent.svelte';

	let { children } = $props();
</script>

<!-- App Shell with responsive layout -->
<div class="min-h-screen-safe flex flex-col bg-gray-50 dark:bg-gray-950">
	<!-- Fixed Header -->
	<Header />

	<!-- Main Layout Container -->
	<div class="flex flex-1 overflow-hidden">
		<!-- Desktop Sidebar Navigation -->
		<Sidebar />

		<!-- Main Content Area -->
		<MainContent>
			{@render children()}
		</MainContent>
	</div>

	<!-- Mobile Bottom Navigation -->
	<BottomNav />
</div>
