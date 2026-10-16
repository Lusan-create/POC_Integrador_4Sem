<template>
  <!-- Layout do Figma "BASE WEB - AZUL": fundo azul-marinho, trilho de ícones à esquerda,
       botão CFG laranja à direita e o conteúdo num painel branco. -->
  <div class="layout">
    <header class="topo nao-imprimir">
      <div class="cfg-area" @keydown.esc="cfgAberto = false"
           @focusout="(e) => !e.currentTarget.contains(e.relatedTarget) && (cfgAberto = false)">
        <button class="cfg" :aria-expanded="cfgAberto" aria-haspopup="menu" @click="cfgAberto = !cfgAberto">CFG</button>
        <nav v-if="cfgAberto" class="cfg-menu" role="menu" @click="cfgAberto = false">
          <RouterLink to="/cadastros" role="menuitem">Categorias e locais</RouterLink>
          <RouterLink to="/usuarios" role="menuitem">Usuários</RouterLink>
          <RouterLink to="/logs" role="menuitem">Logs de auditoria</RouterLink>
        </nav>
      </div>
    </header>

    <nav class="trilho nao-imprimir" aria-label="Menu principal">
      <RouterLink v-for="item in itens" :key="item.para" :to="item.para" :title="item.nome" :aria-label="item.nome"
                  :class="{ ativo: secaoAtual(item.para) }">
        <svg viewBox="0 0 24 24" width="26" height="26" aria-hidden="true"><path :d="item.icone" /></svg>
      </RouterLink>
    </nav>

    <main class="painel">
      <RouterView />
    </main>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()
const cfgAberto = ref(false)
// Mantém o ícone destacado também nas subpáginas (ex.: /ativos/12).
const secaoAtual = (para) => (para === '/' ? route.path === '/' : route.path.startsWith(para))

// Ícones do Material Design (24x24).
const itens = [
  { para: '/', nome: 'Painel', icone: 'M3 13h8V3H3v10zm0 8h8v-6H3v6zm10 0h8V11h-8v10zm0-18v6h8V3h-8z' },
  { para: '/consultar', nome: 'Consultar ativo', icone: 'M15.5 14h-.79l-.28-.27A6.47 6.47 0 0 0 16 9.5 6.5 6.5 0 1 0 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z' },
  { para: '/ativos', nome: 'Ativos', icone: 'M20 2H4c-1 0-2 .9-2 2v3.01c0 .72.43 1.34 1 1.69V20c0 1.1 1.1 2 2 2h14c.9 0 2-.9 2-2V8.7c.57-.35 1-.97 1-1.69V4c0-1.1-1-2-2-2zm-5 12H9v-2h6v2zm5-7H4V4h16v3z' },
  { para: '/ordens-servico', nome: 'Ordens de serviço', icone: 'M22.7 19l-9.1-9.1c.9-2.3.4-5-1.5-6.9-2-2-5-2.4-7.4-1.3L9 6 6 9 1.6 4.7C.4 7.1.9 10.1 2.9 12.1c1.9 1.9 4.6 2.4 6.9 1.5l9.1 9.1c.4.4 1 .4 1.4 0l2.3-2.3c.5-.4.5-1.1.1-1.4z' },
  { para: '/movimentacoes', nome: 'Movimentações', icone: 'M6.99 11L3 15l3.99 4v-3H14v-2H6.99v-3zM21 9l-3.99-4v3H10v2h7.01v3L21 9z' },
]
</script>

<style scoped>
.layout {
  min-height: 100vh; background: var(--marinho);
  display: grid; grid-template-columns: 84px 1fr; grid-template-rows: 86px 1fr;
}
.topo { grid-column: 1 / -1; display: flex; align-items: center; justify-content: flex-end; padding: 0 28px; }
.cfg-area { position: relative; }
.cfg {
  width: 50px; height: 50px; border-radius: 50%; border: 0; cursor: pointer;
  background: var(--destaque); color: #fff; font: inherit; font-size: 12px; font-weight: 700;
}
.cfg:hover { filter: brightness(1.08); }
.cfg-menu {
  position: absolute; right: 0; top: 58px; z-index: 60; min-width: 210px; padding: 6px;
  background: var(--superficie); border-radius: 10px; box-shadow: 0 8px 24px rgb(0 0 0 / .18);
  display: flex; flex-direction: column;
}
.cfg-menu a { color: var(--marinho); padding: 9px 12px; border-radius: 6px; font-weight: 500; }
.cfg-menu a:hover, .cfg-menu a.router-link-active { background: var(--fundo); text-decoration: none; }

.trilho {
  display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 30px;
  position: sticky; top: 0; height: calc(100vh - 86px); align-self: start;
}
.trilho a {
  width: 60px; height: 60px; border-radius: 10px; background: var(--superficie);
  border: 2px solid var(--destaque); display: grid; place-items: center; fill: var(--marinho);
  transition: background .15s, fill .15s;
}
.trilho a:hover { background: var(--azul-claro); }
.trilho a.ativo { background: var(--primaria); fill: #fff; border-color: var(--primaria); }

.painel {
  background: var(--superficie); border-top-left-radius: 10px; min-width: 0;
  padding: 28px 32px;
}

@media (max-width: 640px) {
  .layout { grid-template-columns: 64px 1fr; grid-template-rows: 70px 1fr; }
  .topo { padding: 0 16px; }
  .trilho { height: calc(100vh - 70px); gap: 18px; }
  .trilho a { width: 48px; height: 48px; }
  .painel { padding: 16px; }
}
@media print {
  .layout { display: block; background: none; }
  .painel { padding: 0; }
}
</style>
