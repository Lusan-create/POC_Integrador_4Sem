<template>
  <div>
    <div class="cabecalho-pagina">
      <div>
        <h1>Usuários</h1>
        <p class="subtitulo">Pessoas cadastradas no sistema, que podem ser responsáveis pelos ativos.</p>
      </div>
      <button class="btn btn-primario" @click="abrir()">+ Novo usuário</button>
    </div>

    <div class="cartao sem-padding">
      <div class="tabela-container">
        <table>
          <thead><tr><th>Nome</th><th>E-mail</th><th>Perfil</th><th>Criado em</th><th></th></tr></thead>
          <tbody>
            <tr v-for="u in usuarios" :key="u.id">
              <td><strong>{{ u.nome }}</strong></td>
              <td>{{ u.email }}</td>
              <td><span class="selo" :class="u.cargo === 'admin' ? 'azul' : 'cinza'">{{ u.cargo_exibicao }}</span></td>
              <td>{{ dataHora(u.criado_em) }}</td>
              <td class="acoes">
                <button class="btn btn-pequeno" @click="abrir(u)">Editar</button>
                <button class="btn btn-pequeno btn-perigo" @click="paraExcluir = u">Excluir</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <JanelaModal v-if="form" :titulo="form.id ? 'Editar usuário' : 'Novo usuário'" @fechar="form = null">
      <form @submit.prevent="salvar">
        <div v-if="erroGeral" class="alerta erro">{{ erroGeral }}</div>
        <div class="campo">
          <label for="nome">Nome completo *</label>
          <input id="nome" v-model.trim="form.nome" required maxlength="120" />
          <div v-if="erros.nome" class="erro-campo">{{ erros.nome }}</div>
        </div>
        <div class="campo">
          <label for="email">E-mail *</label>
          <input id="email" v-model.trim="form.email" type="email" required maxlength="255" />
          <div v-if="erros.email" class="erro-campo">{{ erros.email }}</div>
        </div>
        <div class="campos-2">
          <div class="campo">
            <label for="cargo">Perfil *</label>
            <select id="cargo" v-model="form.cargo">
              <option value="user">Usuário</option>
              <option value="admin">Administrador</option>
            </select>
          </div>
          <div class="campo">
            <label for="nasc">Data de nascimento</label>
            <input id="nasc" v-model="form.data_nascimento" type="date" />
          </div>
        </div>
        <div class="campo">
          <label for="senha">{{ form.id ? 'Nova senha (deixe em branco para manter)' : 'Senha *' }}</label>
          <input id="senha" v-model="form.senha" type="password" autocomplete="new-password" :required="!form.id" />
          <div v-if="erros.senha" class="erro-campo">{{ erros.senha }}</div>
          <div class="dica">Mínimo de 8 caracteres; evite senhas comuns ou só com números.</div>
        </div>
        <div class="linha">
          <span class="espaco"></span>
          <button type="button" class="btn" @click="form = null">Cancelar</button>
          <button class="btn btn-primario" :disabled="salvando">Salvar</button>
        </div>
      </form>
    </JanelaModal>

    <JanelaModal v-if="paraExcluir" titulo="Excluir usuário" @fechar="paraExcluir = null">
      <p>Excluir <strong>{{ paraExcluir.nome }}</strong>? O histórico de ações é mantido.</p>
      <div class="linha">
        <span class="espaco"></span>
        <button class="btn" @click="paraExcluir = null">Cancelar</button>
        <button class="btn btn-perigo" @click="excluir">Excluir</button>
      </div>
    </JanelaModal>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { api, errosPorCampo, mensagemDeErro } from '../api/cliente'
import { dataHora } from '../api/rotulos'
import { avisar } from '../components/aviso'
import JanelaModal from '../components/JanelaModal.vue'

const usuarios = ref([])
const form = ref(null)
const erros = ref({})
const erroGeral = ref('')
const salvando = ref(false)
const paraExcluir = ref(null)

async function carregar() {
  usuarios.value = (await api.get('/usuarios/', { params: { page_size: 200 } })).data.results
}

function abrir(u) {
  erros.value = {}
  erroGeral.value = ''
  form.value = u
    ? { id: u.id, nome: u.nome, email: u.email, cargo: u.cargo, data_nascimento: u.data_nascimento || '', senha: '' }
    : { nome: '', email: '', cargo: 'user', data_nascimento: '', senha: '' }
}

async function salvar() {
  erros.value = {}
  erroGeral.value = ''
  salvando.value = true
  const { id, ...dados } = form.value
  if (!dados.senha) delete dados.senha
  dados.data_nascimento = dados.data_nascimento || null
  try {
    if (id) await api.patch(`/usuarios/${id}/`, dados)
    else await api.post('/usuarios/', dados)
    form.value = null
    avisar('Usuário salvo.')
    carregar()
  } catch (e) {
    erros.value = errosPorCampo(e)
    if (!Object.keys(erros.value).length) erroGeral.value = mensagemDeErro(e)
  } finally {
    salvando.value = false
  }
}

async function excluir() {
  try {
    await api.delete(`/usuarios/${paraExcluir.value.id}/`)
    paraExcluir.value = null
    avisar('Usuário excluído.')
    carregar()
  } catch (e) {
    avisar(mensagemDeErro(e), 'erro')
  }
}

onMounted(carregar)
</script>

<style scoped>
.sem-padding { padding: 4px 6px; }
.acoes { text-align: right; white-space: nowrap; }
.acoes .btn { margin-left: 4px; }
.dica { color: var(--texto-suave); font-size: 12px; margin-top: 4px; }
</style>
