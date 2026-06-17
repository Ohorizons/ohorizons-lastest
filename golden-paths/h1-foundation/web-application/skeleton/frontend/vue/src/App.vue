<script setup lang="ts">
import { ref } from 'vue';

const count = ref(0);
</script>

<template>
  <div style="max-width: 800px; margin: 0 auto; padding: 2rem">
    <h1>${{ values.appName }}</h1>
    <p>Welcome to your new application.</p>
    <button @click="count++">Count: {{ count }}</button>
  </div>
</template>
