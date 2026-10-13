<template>
  <div>
    <h1>Logs de auditoria</h1>
    <p class="subtitulo">Registro das principais ações do sistema. Somente leitura; senhas e tokens nunca são gravados.</p>

    <div class="cartao filtros">
      <input v-model="filtros.search" placeholder="Buscar por e-mail ou descrição" @input="buscarComAtraso" />
      <select v-model="filtros.acao" @change="carregar(1)">
        <option value="">Todas as ações</option>
        <option v-for="(t, v) in ACOES" :key="v" :value="v">{{ t }}</option>
      </select>
    </div>

    <div class="cartao sem-padding">
      <div class="tabela-container">
        <table>
          <thead><tr><th>Data</th><th>Usuário</th><th>Ação</th><th>Descrição</th><th>IP</th></tr></thead>
          <tbody>
            <tr v-for="l in logs" :key="l.id">
              <td class="nowrap">{{ dataHora(l.criado_em) }}</td>
              <td>{{ l.usuario_email || '—' }}</td>
              <td><span class="selo" :class="cor(l.acao)">{{ l.acao_exibicao }}</span></td>
              <td>{{ l.descricao }}</td>
              <td class="mono suave">{{ l.ip || '—' }}</td>
            </tr>
            <tr v-if="!logs.length"><td colspan="5" class="vazio">Nenhum registro.</td></tr>
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
import { api } from '../api/cliente'
import { dataHora } from '../api/rotulos'

const ACOES = {
  login: 'Login', login_falha: 'Falha de login', acesso_negado: 'Acesso negado', criar: 'Criação',
  editar: 'Edição', excluir: 'Exclusão', inativar: 'Inativação', reativar: 'Reativação',
  movimentar: 'Movimentação', abrir_os: 'Abertura de OS', atualizar_os: 'Atualização de OS',
}
const logs = ref([])
const total = ref(0)
const pagina = ref(1)
const filtros = reactive({ search: '', acao: '' })
const paginas = computed(() => Math.max(1, Math.ceil(total.value / 20)))

function cor(acao) {
  if (['login_falha', 'acesso_negado', 'excluir', 'inativar'].includes(acao)) return 'laranja'
  if (acao === 'login') return 'cinza'
  return 'azul'
}

let atraso
function buscarComAtraso() {
  clearTimeout(atraso)
  atraso = setTimeout(() => carregar(1), 300)
}

async function carregar(p = pagina.value) {
  const params = { page: p, search: filtros.search || undefined, acao: filtros.acao || undefined }
  const { data } = await api.get('/logs/', { params })
  logs.value = data.results
  total.value = data.count
  pagina.value = p
}

onMounted(() => carregar(1))
</script>

<style scoped>
.filtros { display: grid; grid-template-columns: 2fr 1fr; gap: 10px; margin-bottom: 14px; padding: 12px; }
.sem-padding { padding: 4px 6px; }
.nowrap { white-space: nowrap; }
.suave { color: var(--texto-suave); font-weight: 400; }
</style>
