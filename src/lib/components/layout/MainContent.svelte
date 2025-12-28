<script lang="ts">
	let { children } = $props();
</script>

<!-- Main Content Area - Responsive positioning and padding -->
<main
	class="flex-1 overflow-y-auto
		pt-14 pb-20 md:pb-6
		md:ml-64 lg:ml-72
		bg-gray-50 dark:bg-gray-950"
>
	<!-- Content Container with max width -->
	<div class="container mx-auto px-4 py-6 max-w-2xl lg:max-w-3xl">
		{@render children()}
	</div>
</main>
