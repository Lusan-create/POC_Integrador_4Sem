<template>
  <JanelaModal titulo="Registrar movimentação" @fechar="$emit('fechar')">
    <form @submit.prevent="salvar">
      <p class="info">
        <span class="mono">{{ ativo.identificacao }}</span> — {{ ativo.nome }}<br />
        Local atual: <strong>{{ ativo.localizacao.nome }}</strong>
      </p>
      <div v-if="erro" class="alerta erro">{{ erro }}</div>
      <div class="campo">
        <label for="destino">Novo local *</label>
        <select id="destino" v-model="destino" required>
          <option disabled value="">Selecione</option>
          <option v-for="l in destinos" :key="l.id" :value="l.id">{{ l.nome }}</option>
        </select>
      </div>
      <div class="campo">
        <label for="obs">Observação</label>
        <textarea id="obs" v-model.trim="observacao" maxlength="500" placeholder="Motivo da movimentação"></textarea>
      </div>
      <div class="linha">
        <span class="espaco"></span>
        <button type="button" class="btn" @click="$emit('fechar')">Cancelar</button>
        <button class="btn btn-primario" :disabled="salvando">Registrar</button>
      </div>
    </form>
  </JanelaModal>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { api, mensagemDeErro } from '../api/cliente'
import JanelaModal from './JanelaModal.vue'

const props = defineProps({ ativo: Object })
const emit = defineEmits(['fechar', 'salvo'])
const locais = ref([])
const destino = ref('')
const observacao = ref('')
const erro = ref('')
const salvando = ref(false)
const destinos = computed(() => locais.value.filter((l) => l.id !== props.ativo.localizacao.id))

onMounted(async () => {
  locais.value = (await api.get('/localizacoes/')).data
})

async function salvar() {
  erro.value = ''
  salvando.value = true
  try {
    await api.post('/movimentacoes/', { ativo_id: props.ativo.id, destino_id: destino.value, observacao: observacao.value })
    emit('salvo')
  } catch (e) {
    erro.value = mensagemDeErro(e)
  } finally {
    salvando.value = false
  }
}
</script>

<style scoped>
.info { background: var(--fundo); padding: 10px 12px; border-radius: 8px; margin: 0 0 14px; line-height: 1.6; }
</style>
