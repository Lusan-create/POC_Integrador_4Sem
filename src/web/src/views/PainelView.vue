<template>
  <div>
    <div class="cabecalho-pagina">
      <div>
        <h1>Painel</h1>
        <p class="subtitulo">Visão geral dos ativos e das ordens de serviço.</p>
      </div>
      <RouterLink to="/consultar" class="btn btn-primario">Consultar ativo</RouterLink>
    </div>

    <div v-if="erro" class="alerta erro">{{ erro }}</div>

    <template v-if="dados">
      <div class="indicadores">
        <div class="cartao indicador">
          <span>Total de ativos</span>
          <strong>{{ dados.total_ativos }}</strong>
        </div>
        <div class="cartao indicador">
          <span>Em uso</span>
          <strong>{{ dados.por_status.em_uso }}</strong>
        </div>
        <div class="cartao indicador">
          <span>Disponíveis</span>
          <strong>{{ dados.por_status.disponivel }}</strong>
        </div>
        <RouterLink to="/ordens-servico" class="cartao indicador destaque">
          <span>OS pendentes</span>
          <strong>{{ dados.os_pendentes }}</strong>
        </RouterLink>
        <div class="cartao indicador">
          <span>Movimentações (30 dias)</span>
          <strong>{{ dados.movimentacoes_30_dias }}</strong>
        </div>
      </div>

      <div class="grade grade-2">
        <section class="cartao">
          <h2>Manutenções previstas (próximos 30 dias)</h2>
          <div class="tabela-container">
            <table>
              <thead><tr><th>Patrimônio</th><th>Ativo</th><th>Local</th><th>Prevista para</th></tr></thead>
              <tbody>
                <tr v-for="a in dados.manutencoes_proximas" :key="a.id" class="clicavel" @click="$router.push(`/ativos/${a.id}`)">
                  <td class="mono">{{ a.identificacao }}</td>
                  <td>{{ a.nome }}</td>
                  <td>{{ a.localizacao }}</td>
                  <td>
                    <span :class="{ atrasada: a.atrasada }">{{ data(a.proxima_manutencao) }}</span>
                    <span v-if="a.atrasada" class="selo laranja">atrasada</span>
                  </td>
                </tr>
                <tr v-if="!dados.manutencoes_proximas.length"><td colspan="4" class="vazio">Nenhuma manutenção prevista.</td></tr>
              </tbody>
            </table>
          </div>
        </section>

        <section class="cartao">
          <h2>Ativos por local</h2>
          <div v-for="l in locaisOrdenados" :key="l.id" class="barra-linha">
            <span class="barra-rotulo">{{ l.nome }}</span>
            <div class="barra"><div :style="{ width: `${(l.total / maxLocal) * 100}%` }"></div></div>
            <strong>{{ l.total }}</strong>
          </div>
          <h2 class="mt">Situação dos ativos</h2>
          <div class="linha">
            <span v-for="(qtd, status) in dados.por_status" :key="status" class="linha">
              <SeloStatus :valor="status" /> <strong>{{ qtd }}</strong>&nbsp;&nbsp;
            </span>
          </div>
        </section>
      </div>
    </template>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { api, mensagemDeErro } from '../api/cliente'
import { data } from '../api/rotulos'
import SeloStatus from '../components/SeloStatus.vue'

const dados = ref(null)
const erro = ref('')
const locaisOrdenados = computed(() => [...(dados.value?.por_localizacao || [])].sort((a, b) => b.total - a.total))
const maxLocal = computed(() => Math.max(1, ...locaisOrdenados.value.map((l) => l.total)))

onMounted(async () => {
  try {
    dados.value = (await api.get('/painel/')).data
  } catch (e) {
    erro.value = mensagemDeErro(e)
  }
})
</script>

<style scoped>
.indicadores { display: grid; grid-template-columns: repeat(auto-fit, minmax(170px, 1fr)); gap: 14px; margin-bottom: 16px; }
.indicador { display: flex; flex-direction: column; gap: 6px; color: inherit; }
.indicador span { color: var(--texto-suave); font-size: 13px; }
.indicador strong { font-size: 28px; }
a.indicador:hover { text-decoration: none; border-color: var(--primaria); }
.destaque strong { color: var(--laranja); }
.atrasada { color: var(--vermelho); font-weight: 600; margin-right: 6px; }
.barra-linha { display: grid; grid-template-columns: 130px 1fr 32px; gap: 10px; align-items: center; margin-bottom: 8px; }
.barra-rotulo { font-size: 13px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.barra { background: var(--cinza-fundo); border-radius: 4px; height: 10px; overflow: hidden; }
.barra div { background: var(--primaria); height: 100%; border-radius: 4px; }
.mt { margin-top: 22px; }
</style>
