<script lang="ts">
	import '../app.css';
	import favicon from '$lib/assets/favicon.svg';
	import AppShell from '$lib/components/layout/AppShell.svelte';

	let { children } = $props();
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
	<title>Asocial - A Constructive Social Network</title>
	<meta name="description" content="An anti-propaganda social media platform designed for constructive discourse" />
</svelte:head>

<AppShell>
	{@render children()}
</AppShell>
