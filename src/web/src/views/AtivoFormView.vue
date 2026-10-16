<template>
  <div class="formulario">
    <RouterLink :to="id ? `/ativos/${id}` : '/ativos'" class="voltar" title="Voltar" aria-label="Voltar"><svg viewBox="0 0 48 24" width="48" height="24" aria-hidden="true"><path d="M46 12H4M12 4l-8 8 8 8" /></svg></RouterLink>
    <h1>{{ id ? 'Editar ativo' : 'Novo ativo' }}</h1>
    <p class="subtitulo">Campos com * são obrigatórios.</p>

    <form class="cartao" @submit.prevent="salvar">
      <div v-if="erroGeral" class="alerta erro">{{ erroGeral }}</div>

      <div class="campos-2">
        <div class="campo">
          <label for="identificacao">Patrimônio *</label>
          <input id="identificacao" v-model.trim="form.identificacao" placeholder="PT-000000" maxlength="30" required />
          <div v-if="erros.identificacao" class="erro-campo">{{ erros.identificacao }}</div>
        </div>
        <div class="campo">
          <label for="nome">Nome *</label>
          <input id="nome" v-model.trim="form.nome" maxlength="120" required />
          <div v-if="erros.nome" class="erro-campo">{{ erros.nome }}</div>
        </div>
      </div>

      <div class="campo">
        <label for="descricao">Descrição / características</label>
        <textarea id="descricao" v-model.trim="form.descricao" maxlength="255"></textarea>
      </div>

      <div class="campos-2">
        <div class="campo">
          <label for="categoria">Categoria *</label>
          <select id="categoria" v-model="form.categoria_id" required>
            <option disabled value="">Selecione</option>
            <option v-for="c in categorias" :key="c.id" :value="c.id">{{ c.nome }}</option>
          </select>
          <div v-if="erros.categoria_id" class="erro-campo">{{ erros.categoria_id }}</div>
        </div>
        <div class="campo">
          <label for="local">Local *</label>
          <select id="local" v-model="form.localizacao_id" required :disabled="!!id">
            <option disabled value="">Selecione</option>
            <option v-for="l in locais" :key="l.id" :value="l.id">{{ l.nome }}</option>
          </select>
          <div v-if="id" class="dica">Para mudar o local, registre uma movimentação.</div>
          <div v-if="erros.localizacao_id" class="erro-campo">{{ erros.localizacao_id }}</div>
        </div>
        <div class="campo">
          <label for="responsavel">Responsável</label>
          <select id="responsavel" v-model="form.responsavel_id">
            <option :value="null">Sem responsável</option>
            <option v-for="u in usuarios" :key="u.id" :value="u.id">{{ u.nome }}</option>
          </select>
        </div>
        <div class="campo">
          <label for="status">Situação</label>
          <select id="status" v-model="form.status" :disabled="form.status === 'inativo' || form.status === 'em_manutencao'">
            <option value="disponivel">Disponível</option>
            <option value="em_uso">Em uso</option>
            <option v-if="form.status === 'em_manutencao'" value="em_manutencao">Em manutenção</option>
            <option v-if="form.status === 'inativo'" value="inativo">Inativo</option>
          </select>
        </div>
        <div class="campo">
          <label for="proxima">Próxima manutenção prevista</label>
          <input id="proxima" v-model="form.proxima_manutencao" type="date" />
          <div v-if="erros.proxima_manutencao" class="erro-campo">{{ erros.proxima_manutencao }}</div>
        </div>
      </div>

      <div class="linha">
        <span class="espaco"></span>
        <RouterLink :to="id ? `/ativos/${id}` : '/ativos'" class="btn">Cancelar</RouterLink>
        <button class="btn btn-primario" :disabled="salvando">{{ salvando ? 'Salvando…' : 'Salvar' }}</button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api, errosPorCampo, mensagemDeErro } from '../api/cliente'
import { avisar } from '../components/aviso'

const props = defineProps({ id: String })
const router = useRouter()
const categorias = ref([])
const locais = ref([])
const usuarios = ref([])
const erros = ref({})
const erroGeral = ref('')
const salvando = ref(false)
const form = reactive({
  identificacao: '', nome: '', descricao: '', categoria_id: '', localizacao_id: '',
  responsavel_id: null, status: 'disponivel', proxima_manutencao: '',
})

onMounted(async () => {
  const [c, l, u] = await Promise.all([
    api.get('/categorias/'), api.get('/localizacoes/'), api.get('/usuarios/', { params: { page_size: 100 } }),
  ])
  categorias.value = c.data
  locais.value = l.data
  usuarios.value = u.data.results
  if (props.id) {
    const { data: a } = await api.get(`/ativos/${props.id}/`)
    Object.assign(form, {
      identificacao: a.identificacao, nome: a.nome, descricao: a.descricao,
      categoria_id: a.categoria.id, localizacao_id: a.localizacao.id,
      responsavel_id: a.responsavel?.id ?? null, status: a.status,
      proxima_manutencao: a.proxima_manutencao || '',
    })
  }
})

async function salvar() {
  erros.value = {}
  erroGeral.value = ''
  salvando.value = true
  const dados = { ...form, proxima_manutencao: form.proxima_manutencao || null }
  if (props.id) {
    delete dados.localizacao_id
    if (['inativo', 'em_manutencao'].includes(dados.status)) delete dados.status
  }
  try {
    const { data } = props.id
      ? await api.patch(`/ativos/${props.id}/`, dados)
      : await api.post('/ativos/', dados)
    avisar(props.id ? 'Ativo atualizado.' : 'Ativo cadastrado.')
    router.push(`/ativos/${data.id}`)
  } catch (e) {
    erros.value = errosPorCampo(e)
    if (!Object.keys(erros.value).length) erroGeral.value = mensagemDeErro(e)
  } finally {
    salvando.value = false
  }
}
</script>

<style scoped>
.formulario { max-width: 760px; }
.dica { color: var(--texto-suave); font-size: 12px; margin-top: 4px; }
</style>
