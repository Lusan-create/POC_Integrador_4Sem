<template>
  <JanelaModal :titulo="os ? `Atualizar OS #${os.id}` : 'Abrir ordem de serviço'" @fechar="$emit('fechar')">
    <form @submit.prevent="salvar">
      <p class="info">
        <span class="mono">{{ ativoInfo.identificacao }}</span> — {{ ativoInfo.nome }}
      </p>
      <div v-if="erro" class="alerta erro">{{ erro }}</div>

      <template v-if="!os">
        <div class="campo">
          <label for="tipo">Tipo *</label>
          <select id="tipo" v-model="form.tipo">
            <option value="corretiva">Corretiva (algo quebrou)</option>
            <option value="preventiva">Preventiva (revisão programada)</option>
          </select>
        </div>
        <div class="campo">
          <label for="descricao">Descrição do problema/serviço *</label>
          <textarea id="descricao" v-model.trim="form.descricao" maxlength="500" required></textarea>
        </div>
      </template>

      <div class="campo">
        <label for="status">Situação</label>
        <select id="status" v-model="form.status">
          <option value="aberta">Aberta</option>
          <option value="em_andamento">Em andamento</option>
          <option value="concluida">Concluída</option>
          <option v-if="os" value="cancelada">Cancelada</option>
        </select>
      </div>

      <div v-if="form.status === 'concluida'" class="campos-2">
        <div class="campo">
          <label for="realizada">Realizada em *</label>
          <input id="realizada" v-model="form.realizada_em" type="date" :max="hojeISO()" required />
        </div>
        <div class="campo">
          <label for="proxima">Próxima manutenção</label>
          <input id="proxima" v-model="form.proxima_prevista" type="date" :min="form.realizada_em" />
        </div>
        <div class="campo">
          <label for="custo">Custo (R$)</label>
          <input id="custo" v-model="form.custo" type="number" min="0" step="0.01" />
        </div>
      </div>
      <div v-if="os && form.status !== 'concluida'" class="campo">
        <label for="descricao2">Descrição</label>
        <textarea id="descricao2" v-model.trim="form.descricao" maxlength="500"></textarea>
      </div>

      <div class="linha">
        <span class="espaco"></span>
        <button type="button" class="btn" @click="$emit('fechar')">Cancelar</button>
        <button class="btn btn-primario" :disabled="salvando">{{ os ? 'Salvar' : 'Abrir OS' }}</button>
      </div>
    </form>
  </JanelaModal>
</template>

<script setup>
import { computed, reactive, ref } from 'vue'
import { api, mensagemDeErro } from '../api/cliente'
import { hojeISO } from '../api/rotulos'
import JanelaModal from './JanelaModal.vue'

// Passe `ativo` para abrir uma OS nova, ou `os` para atualizar uma existente.
const props = defineProps({ ativo: Object, os: Object })
const emit = defineEmits(['fechar', 'salvo'])
const ativoInfo = computed(() => props.os?.ativo || props.ativo)
const erro = ref('')
const salvando = ref(false)
const form = reactive({
  tipo: 'corretiva',
  descricao: props.os?.descricao || '',
  status: props.os?.status === 'aberta' ? 'em_andamento' : props.os?.status || 'aberta',
  realizada_em: hojeISO(),
  proxima_prevista: '',
  custo: '',
})

async function salvar() {
  erro.value = ''
  salvando.value = true
  const dados = { status: form.status, descricao: form.descricao }
  if (form.status === 'concluida') {
    dados.realizada_em = form.realizada_em
    dados.proxima_prevista = form.proxima_prevista || null
    dados.custo = form.custo === '' ? null : form.custo
  }
  try {
    if (props.os) await api.patch(`/manutencoes/${props.os.id}/`, dados)
    else await api.post('/manutencoes/', { ...dados, tipo: form.tipo, ativo_id: props.ativo.id })
    emit('salvo')
  } catch (e) {
    erro.value = mensagemDeErro(e)
  } finally {
    salvando.value = false
  }
}
</script>

<style scoped>
.info { background: var(--fundo); padding: 10px 12px; border-radius: 8px; margin: 0 0 14px; }
</style>
