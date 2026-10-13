<template>
  <div>
    <div class="cabecalho-pagina">
      <div>
        <h1>Ativos</h1>
        <p class="subtitulo">{{ total }} ativo(s) encontrado(s)</p>
      </div>
      <RouterLink v-if="auth.ehAdmin" to="/ativos/novo" class="btn btn-primario">+ Novo ativo</RouterLink>
    </div>

    <div class="cartao filtros">
      <input v-model="filtros.search" placeholder="Buscar por patrimônio, nome ou descrição" @input="buscarComAtraso" />
      <select v-model="filtros.status" @change="carregar(1)">
        <option value="">Todas as situações</option>
        <option v-for="(s, chave) in STATUS_ATIVO" :key="chave" :value="chave">{{ s.texto }}</option>
      </select>
      <select v-model="filtros.categoria" @change="carregar(1)">
        <option value="">Todas as categorias</option>
        <option v-for="c in categorias" :key="c.id" :value="c.id">{{ c.nome }}</option>
      </select>
      <select v-model="filtros.localizacao" @change="carregar(1)">
        <option value="">Todos os locais</option>
        <option v-for="l in locais" :key="l.id" :value="l.id">{{ l.nome }}</option>
      </select>
    </div>

    <div v-if="erro" class="alerta erro">{{ erro }}</div>

    <div class="cartao sem-padding">
      <div class="tabela-container">
        <table>
          <thead>
            <tr><th>Patrimônio</th><th>Nome</th><th>Categoria</th><th>Local</th><th>Responsável</th><th>Situação</th></tr>
          </thead>
          <tbody>
            <tr v-for="a in ativos" :key="a.id" class="clicavel" @click="$router.push(`/ativos/${a.id}`)">
              <td class="mono">{{ a.identificacao }}</td>
              <td>{{ a.nome }}</td>
              <td>{{ a.categoria.nome }}</td>
              <td>{{ a.localizacao.nome }}</td>
              <td>{{ a.responsavel?.nome || '—' }}</td>
              <td><SeloStatus :valor="a.status" /></td>
            </tr>
            <tr v-if="!carregando && !ativos.length"><td colspan="6" class="vazio">Nenhum ativo encontrado.</td></tr>
            <tr v-if="carregando"><td colspan="6" class="vazio">Carregando…</td></tr>
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
import { STATUS_ATIVO } from '../api/rotulos'
import SeloStatus from '../components/SeloStatus.vue'
import { useAuthStore } from '../stores/auth'

const auth = useAuthStore()
const ativos = ref([])
const categorias = ref([])
const locais = ref([])
const total = ref(0)
const pagina = ref(1)
const erro = ref('')
const carregando = ref(false)
const filtros = reactive({ search: '', status: '', categoria: '', localizacao: '' })
const paginas = computed(() => Math.max(1, Math.ceil(total.value / 20)))

let atraso
function buscarComAtraso() {
  clearTimeout(atraso)
  atraso = setTimeout(() => carregar(1), 300)
}

async function carregar(p = pagina.value) {
  carregando.value = true
  erro.value = ''
  try {
    const params = Object.fromEntries(Object.entries(filtros).filter(([, v]) => v !== ''))
    const { data } = await api.get('/ativos/', { params: { ...params, page: p } })
    ativos.value = data.results
    total.value = data.count
    pagina.value = p
  } catch (e) {
    erro.value = mensagemDeErro(e)
  } finally {
    carregando.value = false
  }
}

onMounted(async () => {
  carregar(1)
  const [c, l] = await Promise.all([api.get('/categorias/'), api.get('/localizacoes/')])
  categorias.value = c.data
  locais.value = l.data
})
</script>

<style scoped>
.filtros { display: grid; grid-template-columns: 2fr 1fr 1fr 1fr; gap: 10px; margin-bottom: 14px; padding: 12px; }
@media (max-width: 860px) { .filtros { grid-template-columns: 1fr 1fr; } }
.sem-padding { padding: 4px 6px; }
</style>
