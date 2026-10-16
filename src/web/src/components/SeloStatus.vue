<template>
  <span class="selo" :class="info.cor">{{ info.texto }}</span>
</template>

<script setup>
import { computed } from 'vue'
import { STATUS_ATIVO, STATUS_OS } from '../api/rotulos'

const props = defineProps({ valor: String, tipo: { type: String, default: 'ativo' } })
const info = computed(() => {
  const mapa = props.tipo === 'os' ? STATUS_OS : STATUS_ATIVO
  return mapa[props.valor] || { texto: props.valor, cor: 'cinza' }
})
</script>
