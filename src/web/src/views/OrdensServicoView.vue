<template>
  <div>
    <div class="cabecalho-pagina">
      <div>
        <h1>Ordens de serviço</h1>
        <p class="subtitulo">Manutenções corretivas e preventivas dos ativos.</p>
      </div>
    </div>

    <div class="cartao filtros">
      <input v-model="filtros.search" placeholder="Buscar por patrimônio, ativo ou descrição" @input="buscarComAtraso" />
      <select v-model="filtros.status" @change="carregar(1)">
        <option value="">Todas as situações</option>
        <option value="pendentes">Pendentes (aberta / em andamento)</option>
        <option v-for="(s, chave) in STATUS_OS" :key="chave" :value="chave">{{ s.texto }}</option>
      </select>
      <select v-model="filtros.tipo" @change="carregar(1)">
        <option value="">Todos os tipos</option>
        <option v-for="(t, chave) in TIPO_OS" :key="chave" :value="chave">{{ t }}</option>
      </select>
    </div>

    <div v-if="erro" class="alerta erro">{{ erro }}</div>

    <div class="cartao sem-padding">
      <div class="tabela-container">
        <table>
          <thead>
            <tr><th>OS</th><th>Ativo</th><th>Tipo</th><th>Descrição</th><th>Aberta em</th><th>Situação</th><th></th></tr>
          </thead>
          <tbody>
            <tr v-for="o in ordens" :key="o.id">
              <td class="mono">#{{ o.id }}</td>
              <td><RouterLink :to="`/ativos/${o.ativo.id}`" class="mono">{{ o.ativo.identificacao }}</RouterLink><br /><small>{{ o.ativo.nome }}</small></td>
              <td>{{ o.tipo_exibicao }}</td>
              <td class="desc">{{ o.descricao }}</td>
              <td>{{ dataHora(o.aberta_em) }}</td>
              <td><SeloStatus :valor="o.status" tipo="os" /></td>
              <td>
                <button v-if="['aberta', 'em_andamento'].includes(o.status)" class="btn btn-pequeno" @click="selecionada = o">Atualizar</button>
              </td>
            </tr>
            <tr v-if="!ordens.length"><td colspan="7" class="vazio">Nenhuma ordem de serviço encontrada.</td></tr>
          </tbody>
        </table>
      </div>
    </div>

    <div v-if="paginas > 1" class="paginacao">
      <button class="btn btn-pequeno" :disabled="pagina === 1" @click="carregar(pagina - 1)">Anterior</button>
      Página {{ pagina }} de {{ paginas }}
      <button class="btn btn-pequeno" :disabled="pagina === paginas" @click="carregar(pagina + 1)">Próxima</button>
    </div>

    <ModalOrdemServico v-if="selecionada" :os="selecionada" @fechar="selecionada = null" @salvo="salvo" />
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { api, mensagemDeErro } from '../api/cliente'
import { STATUS_OS, TIPO_OS, dataHora } from '../api/rotulos'
import { avisar } from '../components/aviso'
import ModalOrdemServico from '../components/ModalOrdemServico.vue'
import SeloStatus from '../components/SeloStatus.vue'

const ordens = ref([])
const total = ref(0)
const pagina = ref(1)
const erro = ref('')
const selecionada = ref(null)
const filtros = reactive({ search: '', status: 'pendentes', tipo: '' })
const paginas = computed(() => Math.max(1, Math.ceil(total.value / 20)))

let atraso
function buscarComAtraso() {
  clearTimeout(atraso)
  atraso = setTimeout(() => carregar(1), 300)
}

async function carregar(p = pagina.value) {
  erro.value = ''
  const params = { page: p, search: filtros.search || undefined, tipo: filtros.tipo || undefined }
  if (filtros.status === 'pendentes') params.status__in = 'aberta,em_andamento'
  else if (filtros.status) params.status = filtros.status
  try {
    const { data } = await api.get('/manutencoes/', { params })
    ordens.value = data.results
    total.value = data.count
    pagina.value = p
  } catch (e) {
    erro.value = mensagemDeErro(e)
  }
}

function salvo() {
  selecionada.value = null
  avisar('OS atualizada.')
  carregar()
}

onMounted(() => carregar(1))
</script>

<style scoped>
.filtros { display: grid; grid-template-columns: 2fr 1fr 1fr; gap: 10px; margin-bottom: 14px; padding: 12px; }
@media (max-width: 760px) { .filtros { grid-template-columns: 1fr; } }
.sem-padding { padding: 4px 6px; }
.desc { max-width: 320px; }
small { color: var(--texto-suave); }
</style>
