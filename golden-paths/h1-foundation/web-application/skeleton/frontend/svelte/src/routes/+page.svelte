<script lang="ts">
  let count = 0;
</script>

<div style="max-width: 800px; margin: 0 auto; padding: 2rem;">
  <h1>${{ values.appName }}</h1>
  <p>Welcome to your new application.</p>
  <button on:click={() => count++}>Count: {count}</button>
</div>
