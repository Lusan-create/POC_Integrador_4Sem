<template>
  <div class="avisos" aria-live="polite">
    <div v-for="a in avisos.lista" :key="a.id" class="aviso" :class="a.tipo">{{ a.texto }}</div>
  </div>
</template>

<script setup>
import { avisos } from './aviso'
</script>

<style scoped>
.avisos { position: fixed; right: 16px; bottom: 16px; display: grid; gap: 8px; z-index: 100; }
.aviso {
  padding: 10px 14px; border-radius: 8px; color: #fff; font-weight: 500; max-width: 360px;
  box-shadow: 0 6px 20px rgba(0, 0, 0, .15); background: #1f8a4c;
}
.aviso.erro { background: #c0392b; }
</style>
