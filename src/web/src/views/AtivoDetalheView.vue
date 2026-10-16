<template>
  <div v-if="erro" class="alerta erro">{{ erro }}</div>
  <div v-else-if="ativo">
    <RouterLink to="/ativos" class="voltar nao-imprimir" title="Voltar para Ativos" aria-label="Voltar para Ativos"><svg viewBox="0 0 48 24" width="48" height="24" aria-hidden="true"><path d="M46 12H4M12 4l-8 8 8 8" /></svg></RouterLink>
    <div class="cabecalho-pagina">
      <div>
        <div class="linha">
          <h1>{{ ativo.nome }}</h1>
          <SeloStatus :valor="ativo.status" />
        </div>
        <p class="subtitulo mono">{{ ativo.identificacao }}</p>
      </div>
      <div class="linha nao-imprimir">
        <template v-if="!inativo">
          <button class="btn" @click="modal = 'movimentar'">Movimentar</button>
          <button class="btn" @click="modal = 'os'">Abrir OS</button>
        </template>
        <RouterLink :to="`/ativos/${ativo.id}/editar`" class="btn">Editar</RouterLink>
        <button v-if="!inativo" class="btn btn-perigo" @click="confirmarInativar = true">Inativar</button>
        <button v-else class="btn" @click="reativar">Reativar</button>
      </div>
    </div>

    <div v-if="confirmarInativar" class="alerta erro confirmacao nao-imprimir">
      <span>Inativar <strong>{{ ativo.identificacao }}</strong>? Ele deixará de ser tratado como disponível,
        OS pendentes serão canceladas e o histórico será mantido.</span>
      <span class="linha">
        <button class="btn btn-pequeno" @click="confirmarInativar = false">Cancelar</button>
        <button class="btn btn-pequeno btn-perigo" @click="inativar">Confirmar inativação</button>
      </span>
    </div>

    <div class="grade detalhe">
      <section class="cartao">
        <h2>Dados do ativo</h2>
        <dl class="dados">
          <div><dt>Patrimônio</dt><dd class="mono">{{ ativo.identificacao }}</dd></div>
          <div><dt>Categoria</dt><dd>{{ ativo.categoria.nome }}</dd></div>
          <div><dt>Local</dt><dd>{{ ativo.localizacao.nome }}</dd></div>
          <div><dt>Responsável</dt><dd>{{ ativo.responsavel?.nome || '—' }}</dd></div>
          <div><dt>Última manutenção</dt><dd>{{ data(ativo.ultima_manutencao) }}</dd></div>
          <div><dt>Próxima manutenção</dt><dd>{{ data(ativo.proxima_manutencao) }}</dd></div>
          <div><dt>Cadastrado em</dt><dd>{{ dataHora(ativo.criado_em) }}</dd></div>
          <div><dt>Atualizado em</dt><dd>{{ dataHora(ativo.atualizado_em) }}</dd></div>
        </dl>
        <p v-if="ativo.descricao" class="descricao">{{ ativo.descricao }}</p>
      </section>

      <section class="cartao etiqueta">
        <h2 class="nao-imprimir">Etiqueta</h2>
        <img v-if="qr" :src="qr" :alt="`QR Code ${ativo.identificacao}`" />
        <div class="mono">{{ ativo.identificacao }}</div>
        <small>{{ ativo.nome }}</small>
        <button class="btn btn-pequeno nao-imprimir" @click="imprimir">Imprimir etiqueta</button>
      </section>
    </div>

    <section class="cartao nao-imprimir">
      <h2>Histórico</h2>
      <ol class="linha-tempo">
        <li v-for="ev in eventos" :key="`${ev.tipo}-${ev.registro.id}`" :class="ev.tipo">
          <div class="ponto"></div>
          <div class="evento">
            <template v-if="ev.tipo === 'movimentacao'">
              <strong>Movimentação:</strong> {{ ev.registro.origem.nome }} → {{ ev.registro.destino.nome }}
              <div v-if="ev.registro.observacao" class="obs">{{ ev.registro.observacao }}</div>
            </template>
            <template v-else>
              <div class="linha">
                <strong>OS #{{ ev.registro.id }} — {{ ev.registro.tipo_exibicao }}</strong>
                <SeloStatus :valor="ev.registro.status" tipo="os" />
                <button
                  v-if="['aberta', 'em_andamento'].includes(ev.registro.status)"
                  class="btn btn-pequeno" @click="osSelecionada = ev.registro"
                >Atualizar</button>
              </div>
              <div class="obs">{{ ev.registro.descricao }}</div>
              <div v-if="ev.registro.realizada_em" class="obs">
                Realizada em {{ data(ev.registro.realizada_em) }} · Custo {{ moeda(ev.registro.custo) }}
              </div>
            </template>
            <small>{{ dataHora(ev.data) }} · {{ ev.registro.registrado_por?.nome || 'usuário removido' }}</small>
          </div>
        </li>
        <li v-if="!eventos.length" class="vazio">Nenhum registro no histórico.</li>
      </ol>
    </section>

    <ModalMovimentar v-if="modal === 'movimentar'" :ativo="ativo" @fechar="modal = null" @salvo="aposSalvar('Movimentação registrada.')" />
    <ModalOrdemServico v-if="modal === 'os'" :ativo="ativo" @fechar="modal = null" @salvo="aposSalvar('Ordem de serviço aberta.')" />
    <ModalOrdemServico v-if="osSelecionada" :os="osSelecionada" @fechar="osSelecionada = null" @salvo="aposSalvar('OS atualizada.')" />
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { api, mensagemDeErro } from '../api/cliente'
import { data, dataHora, moeda } from '../api/rotulos'
import { avisar } from '../components/aviso'
import ModalMovimentar from '../components/ModalMovimentar.vue'
import ModalOrdemServico from '../components/ModalOrdemServico.vue'
import SeloStatus from '../components/SeloStatus.vue'

const props = defineProps({ id: String })
const ativo = ref(null)
const eventos = ref([])
const qr = ref('')
const erro = ref('')
const modal = ref(null)
const osSelecionada = ref(null)
const confirmarInativar = ref(false)
const inativo = computed(() => ativo.value?.status === 'inativo')

async function carregar() {
  erro.value = ''
  try {
    const { data: h } = await api.get(`/ativos/${props.id}/historico/`)
    ativo.value = h.ativo
    eventos.value = h.eventos
    if (!qr.value) {
      // A imagem precisa do token, por isso é baixada pelo axios e não por <img src>.
      const img = await api.get(`/ativos/${props.id}/qrcode/`, { responseType: 'blob' })
      qr.value = URL.createObjectURL(img.data)
    }
  } catch (e) {
    erro.value = e.response?.status === 404 ? 'Ativo não encontrado.' : mensagemDeErro(e)
  }
}

function aposSalvar(msg) {
  modal.value = null
  osSelecionada.value = null
  avisar(msg)
  carregar()
}

async function inativar() {
  try {
    await api.post(`/ativos/${props.id}/inativar/`)
    confirmarInativar.value = false
    aposSalvar('Ativo inativado.')
  } catch (e) {
    avisar(mensagemDeErro(e), 'erro')
  }
}

async function reativar() {
  try {
    await api.post(`/ativos/${props.id}/reativar/`)
    aposSalvar('Ativo reativado.')
  } catch (e) {
    avisar(mensagemDeErro(e), 'erro')
  }
}

function imprimir() {
  window.print()
}

watch(() => props.id, () => {
  if (qr.value) URL.revokeObjectURL(qr.value)
  qr.value = ''
  carregar()
}, { immediate: true })
onBeforeUnmount(() => qr.value && URL.revokeObjectURL(qr.value))
</script>

<style scoped>
.detalhe { grid-template-columns: 1fr 240px; margin-bottom: 16px; }
@media (max-width: 760px) { .detalhe { grid-template-columns: 1fr; } }
.descricao { color: var(--texto-suave); margin: 16px 0 0; }
.etiqueta { display: flex; flex-direction: column; align-items: center; gap: 6px; text-align: center; }
.etiqueta h2 { align-self: flex-start; }
.etiqueta img { width: 170px; height: 170px; image-rendering: pixelated; }
.etiqueta small { color: var(--texto-suave); }
.confirmacao { display: flex; justify-content: space-between; align-items: center; gap: 12px; flex-wrap: wrap; }
.linha-tempo { list-style: none; margin: 0; padding: 0; }
.linha-tempo li { display: flex; gap: 12px; padding-bottom: 16px; position: relative; }
.linha-tempo li:not(:last-child)::before {
  content: ''; position: absolute; left: 5px; top: 14px; bottom: 0; width: 2px; background: var(--borda);
}
.ponto { width: 12px; height: 12px; border-radius: 50%; background: var(--primaria); margin-top: 4px; flex-shrink: 0; }
.manutencao .ponto { background: var(--laranja); }
.evento { flex: 1; }
.evento small { color: var(--texto-suave); }
.obs { color: var(--texto-suave); margin: 3px 0; }

@media print {
  /* Imprime só a etiqueta */
  .detalhe { display: block; }
  .detalhe > section:first-child, .cabecalho-pagina, .alerta { display: none; }
  .etiqueta { border: 1px dashed #999; width: 6cm; margin: 0 auto; }
}
</style>
