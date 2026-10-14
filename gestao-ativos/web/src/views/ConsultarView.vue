<template>
  <div class="centro">
    <h1>Consultar ativo</h1>
    <p class="subtitulo">Digite o número de patrimônio ou use o leitor de código de barras (ele digita o código e confirma).</p>

    <form class="cartao" @submit.prevent="consultar">
      <div class="campo">
        <label for="codigo">Código do ativo</label>
        <input id="codigo" ref="campo" v-model.trim="codigo" placeholder="Ex.: PT-000324" autocomplete="off" required />
      </div>
      <button class="btn btn-primario largo" :disabled="carregando">{{ carregando ? 'Consultando…' : 'Consultar' }}</button>
      <div v-if="erro" class="alerta erro mt">{{ erro }}</div>
    </form>
    <p class="dica">No celular, use o aplicativo para ler o QR Code com a câmera.</p>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api, mensagemDeErro } from '../api/cliente'

const router = useRouter()
const codigo = ref('')
const erro = ref('')
const carregando = ref(false)
const campo = ref(null)

onMounted(() => campo.value?.focus())

async function consultar() {
  erro.value = ''
  carregando.value = true
  try {
    const { data } = await api.get(`/ativos/codigo/${encodeURIComponent(codigo.value)}/`)
    router.push(`/ativos/${data.id}`)
  } catch (e) {
    erro.value = e.response?.status === 404 ? `Nenhum ativo encontrado com o código "${codigo.value}".` : mensagemDeErro(e)
    campo.value?.select()
  } finally {
    carregando.value = false
  }
}
</script>

<style scoped>
.centro { max-width: 460px; margin: 40px auto 0; }
.largo { width: 100%; }
.mt { margin: 14px 0 0; }
.dica { color: var(--texto-suave); font-size: 13px; text-align: center; margin-top: 14px; }
</style>
