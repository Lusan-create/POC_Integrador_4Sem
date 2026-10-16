<template>
  <div class="fundo-modal" @mousedown.self="$emit('fechar')">
    <div class="modal" role="dialog" aria-modal="true">
      <header>
        <h3>{{ titulo }}</h3>
        <button class="btn-icone" title="Fechar" @click="$emit('fechar')">✕</button>
      </header>
      <slot />
    </div>
  </div>
</template>

<script setup>
defineProps({ titulo: String })
defineEmits(['fechar'])
</script>

<style scoped>
.fundo-modal {
  position: fixed; inset: 0; background: rgba(15, 23, 42, .45); display: grid; place-items: center;
  z-index: 50; padding: 16px;
}
.modal { background: var(--superficie); border-radius: 12px; padding: 20px; width: min(520px, 100%); max-height: 90vh; overflow: auto; }
header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
h3 { margin: 0; }
</style>
