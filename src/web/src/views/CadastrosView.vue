<template>
  <div>
    <h1>Categorias e locais</h1>
    <p class="subtitulo">Itens usados no cadastro dos ativos. Só é possível excluir itens sem ativos vinculados.</p>

    <div class="grade grade-2">
      <section v-for="secao in secoes" :key="secao.rota" class="cartao">
        <h2>{{ secao.titulo }}</h2>
        <form class="linha novo" @submit.prevent="adicionar(secao)">
          <input v-model.trim="secao.novo.nome" :placeholder="`Nova ${secao.singular}`" maxlength="80" required />
          <input v-if="secao.comDescricao" v-model.trim="secao.novo.descricao" placeholder="Descrição (opcional)" maxlength="255" />
          <button class="btn btn-primario">Adicionar</button>
        </form>
        <table>
          <tbody>
            <tr v-for="item in secao.itens" :key="item.id">
              <template v-if="secao.editando?.id === item.id">
                <td colspan="2">
                  <div class="linha">
                    <input v-model.trim="secao.editando.nome" maxlength="80" />
                    <input v-if="secao.comDescricao" v-model.trim="secao.editando.descricao" maxlength="255" />
                  </div>
                </td>
                <td class="acoes">
                  <button class="btn btn-pequeno btn-primario" @click="salvarEdicao(secao)">Salvar</button>
                  <button class="btn btn-pequeno" @click="secao.editando = null">Cancelar</button>
                </td>
              </template>
              <template v-else>
                <td><strong>{{ item.nome }}</strong></td>
                <td class="suave">{{ item.descricao || '' }}</td>
                <td class="acoes">
                  <button class="btn btn-pequeno" @click="secao.editando = { ...item }">Editar</button>
                  <button class="btn btn-pequeno btn-perigo" @click="excluir(secao, item)">Excluir</button>
                </td>
              </template>
            </tr>
          </tbody>
        </table>
      </section>
    </div>
  </div>
</template>

<script setup>
import { onMounted, reactive } from 'vue'
import { api, mensagemDeErro } from '../api/cliente'
import { avisar } from '../components/aviso'

const secoes = reactive([
  { titulo: 'Categorias', singular: 'categoria', rota: '/categorias/', itens: [], novo: { nome: '' }, editando: null, comDescricao: false },
  { titulo: 'Locais', singular: 'localização', rota: '/localizacoes/', itens: [], novo: { nome: '', descricao: '' }, editando: null, comDescricao: true },
])

async function carregar(secao) {
  secao.itens = (await api.get(secao.rota)).data
}

async function adicionar(secao) {
  try {
    await api.post(secao.rota, secao.novo)
    secao.novo = { nome: '', descricao: '' }
    avisar('Item adicionado.')
    carregar(secao)
  } catch (e) {
    avisar(mensagemDeErro(e), 'erro')
  }
}

async function salvarEdicao(secao) {
  try {
    const { id, nome, descricao } = secao.editando
    await api.patch(`${secao.rota}${id}/`, secao.comDescricao ? { nome, descricao } : { nome })
    secao.editando = null
    avisar('Item atualizado.')
    carregar(secao)
  } catch (e) {
    avisar(mensagemDeErro(e), 'erro')
  }
}

async function excluir(secao, item) {
  try {
    await api.delete(`${secao.rota}${item.id}/`)
    avisar('Item excluído.')
    carregar(secao)
  } catch (e) {
    avisar(mensagemDeErro(e), 'erro')
  }
}

onMounted(() => secoes.forEach(carregar))
</script>

<style scoped>
.novo { margin-bottom: 12px; flex-wrap: nowrap; }
.acoes { text-align: right; white-space: nowrap; }
.acoes .btn { margin-left: 4px; }
.suave { color: var(--texto-suave); font-size: 13px; }
</style>
