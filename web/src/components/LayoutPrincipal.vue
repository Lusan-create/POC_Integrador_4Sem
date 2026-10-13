<template>
  <div class="layout">
    <aside class="menu nao-imprimir" :class="{ aberto: menuAberto }">
      <div class="marca">
        <img src="/favicon.svg" alt="" width="28" height="28" />
        <span>Gestão de Ativos</span>
      </div>
      <nav @click="menuAberto = false">
        <RouterLink to="/" exact-active-class="ativo">Painel</RouterLink>
        <RouterLink to="/consultar" active-class="ativo">Consultar ativo</RouterLink>
        <RouterLink to="/ativos" active-class="ativo">Ativos</RouterLink>
        <RouterLink to="/ordens-servico" active-class="ativo">Ordens de serviço</RouterLink>
        <RouterLink to="/movimentacoes" active-class="ativo">Movimentações</RouterLink>
        <template v-if="auth.ehAdmin">
          <span class="grupo">Administração</span>
          <RouterLink to="/cadastros" active-class="ativo">Categorias e locais</RouterLink>
          <RouterLink to="/usuarios" active-class="ativo">Usuários</RouterLink>
          <RouterLink to="/logs" active-class="ativo">Logs de auditoria</RouterLink>
        </template>
      </nav>
      <div class="usuario">
        <div>
          <strong>{{ auth.usuario?.nome }}</strong>
          <small>{{ auth.usuario?.cargo_exibicao }}</small>
        </div>
        <button class="btn btn-pequeno" @click="sair">Sair</button>
      </div>
    </aside>

    <div class="conteudo">
      <header class="topo nao-imprimir">
        <button class="btn-icone" aria-label="Abrir menu" @click="menuAberto = !menuAberto">☰</button>
        <strong>Gestão de Ativos</strong>
      </header>
      <main>
        <RouterView />
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const auth = useAuthStore()
const router = useRouter()
const menuAberto = ref(false)

function sair() {
  auth.sair()
  router.push('/login')
}
</script>

<style scoped>
.layout { display: flex; min-height: 100vh; }
.menu {
  width: 240px; flex-shrink: 0; background: #151b2e; color: #c9cfdf; display: flex; flex-direction: column;
  padding: 18px 12px; position: sticky; top: 0; height: 100vh;
}
.marca { display: flex; align-items: center; gap: 10px; color: #fff; font-weight: 700; font-size: 16px; padding: 0 8px 18px; }
nav { display: flex; flex-direction: column; gap: 2px; flex: 1; }
nav a { color: #c9cfdf; padding: 9px 10px; border-radius: 8px; font-weight: 500; }
nav a:hover { background: #222a42; text-decoration: none; color: #fff; }
nav a.ativo { background: var(--primaria); color: #fff; }
.grupo { font-size: 11px; text-transform: uppercase; letter-spacing: .06em; color: #7c849b; padding: 16px 10px 6px; }
.usuario { display: flex; align-items: center; justify-content: space-between; gap: 8px; border-top: 1px solid #2a3149; padding: 14px 8px 0; }
.usuario strong { display: block; color: #fff; font-size: 13px; }
.usuario small { color: #7c849b; }
.conteudo { flex: 1; min-width: 0; }
main { padding: 28px; max-width: 1200px; margin: 0 auto; }
.topo { display: none; }

@media (max-width: 860px) {
  .menu { position: fixed; left: -260px; z-index: 40; transition: left .2s; }
  .menu.aberto { left: 0; }
  .topo { display: flex; align-items: center; gap: 10px; padding: 12px 16px; background: #fff; border-bottom: 1px solid var(--borda); }
  main { padding: 16px; }
}
@media print {
  main { padding: 0; }
}
</style>
