<template>
  <div>
    <div class="cabecalho-pagina">
      <div>
        <h1>Movimentações</h1>
        <p class="subtitulo">Histórico de mudanças de local dos ativos.</p>
      </div>
    </div>

    <div class="cartao filtros">
      <select v-model="filtros.destino" @change="carregar(1)">
        <option value="">Qualquer destino</option>
        <option v-for="l in locais" :key="l.id" :value="l.id">{{ l.nome }}</option>
      </select>
      <select v-model="filtros.origem" @change="carregar(1)">
        <option value="">Qualquer origem</option>
        <option v-for="l in locais" :key="l.id" :value="l.id">{{ l.nome }}</option>
      </select>
    </div>

    <div v-if="erro" class="alerta erro">{{ erro }}</div>

    <div class="cartao sem-padding">
      <div class="tabela-container">
        <table>
          <thead><tr><th>Data</th><th>Ativo</th><th>Origem</th><th>Destino</th><th>Observação</th><th>Registrado por</th></tr></thead>
          <tbody>
            <tr v-for="m in movimentacoes" :key="m.id">
              <td>{{ dataHora(m.realizada_em) }}</td>
              <td><RouterLink :to="`/ativos/${m.ativo.id}`" class="mono">{{ m.ativo.identificacao }}</RouterLink><br /><small>{{ m.ativo.nome }}</small></td>
              <td>{{ m.origem.nome }}</td>
              <td>{{ m.destino.nome }}</td>
              <td>{{ m.observacao || '—' }}</td>
              <td>{{ m.registrado_por?.nome || '—' }}</td>
            </tr>
            <tr v-if="!movimentacoes.length"><td colspan="6" class="vazio">Nenhuma movimentação registrada.</td></tr>
          </tbody>
        </table>
      </div>
    </div>

    <div v-if="paginas > 1" class="paginacao">
      <button class="btn btn-pequeno" :disabled="pagina === 1" @click="carregar(pagina - 1)">Anterior</button>
      Página {{ pagina }} de {{ paginas }}
      <button class="btn btn-pequeno" :disabled="pagina === paginas" @click="carregar(pagina + 1)">Próxima</button>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { api, mensagemDeErro } from '../api/cliente'
import { dataHora } from '../api/rotulos'

const movimentacoes = ref([])
const locais = ref([])
const total = ref(0)
const pagina = ref(1)
const erro = ref('')
const filtros = reactive({ origem: '', destino: '' })
const paginas = computed(() => Math.max(1, Math.ceil(total.value / 20)))

async function carregar(p = pagina.value) {
  erro.value = ''
  try {
    const params = { page: p, origem: filtros.origem || undefined, destino: filtros.destino || undefined }
    const { data } = await api.get('/movimentacoes/', { params })
    movimentacoes.value = data.results
    total.value = data.count
    pagina.value = p
  } catch (e) {
    erro.value = mensagemDeErro(e)
  }
}

onMounted(async () => {
  carregar(1)
  locais.value = (await api.get('/localizacoes/')).data
})
</script>

<style scoped>
.filtros { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-bottom: 14px; padding: 12px; max-width: 520px; }
.sem-padding { padding: 4px 6px; }
small { color: var(--texto-suave); }
</style>
