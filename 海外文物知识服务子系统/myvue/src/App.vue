<template>
  <div id="app">
    <router-view v-if="isRouterAlive" />
  </div>
</template>

<script setup>
import { ref, provide } from 'vue'

const isRouterAlive = ref(true)

const reload = () => {
  isRouterAlive.value = false
  setTimeout(() => {
    isRouterAlive.value = true
  }, 0)
}

provide('reload', reload)
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

#app {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

a {
  text-decoration: none;
}
</style>
