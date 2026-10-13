<template>
  <div class="tela">
    <form class="cartao caixa" @submit.prevent="entrar">
      <div class="marca">
        <img src="/favicon.svg" alt="" width="40" height="40" />
        <div>
          <h1>Gestão de Ativos</h1>
          <p class="subtitulo">Entre com seu e-mail e senha</p>
        </div>
      </div>

      <div v-if="route.query.expirada" class="alerta info">Sua sessão expirou. Entre novamente.</div>
      <div v-if="erro" class="alerta erro">{{ erro }}</div>

      <div class="campo">
        <label for="email">E-mail</label>
        <input id="email" v-model.trim="email" type="email" autocomplete="username" required autofocus />
      </div>
      <div class="campo">
        <label for="senha">Senha</label>
        <input id="senha" v-model="senha" type="password" autocomplete="current-password" required />
      </div>
      <button class="btn btn-primario largo" :disabled="carregando">
        {{ carregando ? 'Entrando…' : 'Entrar' }}
      </button>
    </form>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { mensagemDeErro } from '../api/cliente'
import { useAuthStore } from '../stores/auth'

const auth = useAuthStore()
const route = useRoute()
const router = useRouter()
const email = ref('')
const senha = ref('')
const erro = ref('')
const carregando = ref(false)

async function entrar() {
  erro.value = ''
  carregando.value = true
  try {
    await auth.entrar(email.value, senha.value)
    const voltar = route.query.voltar
    router.push(typeof voltar === 'string' && voltar.startsWith('/') ? voltar : '/')
  } catch (e) {
    erro.value = e.response?.status === 401 ? 'E-mail ou senha inválidos.' : mensagemDeErro(e)
  } finally {
    carregando.value = false
    senha.value = ''
  }
}
</script>

<style scoped>
.tela { min-height: 100vh; display: grid; place-items: center; padding: 16px; }
.caixa { width: min(380px, 100%); padding: 28px; }
.marca { display: flex; gap: 12px; align-items: center; margin-bottom: 18px; }
.marca .subtitulo { margin: 0; }
.largo { width: 100%; }
</style>
