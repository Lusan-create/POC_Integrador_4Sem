import { createRouter, createWebHistory } from 'vue-router'

const rotas = [
  {
    path: '/',
    component: () => import('../components/LayoutPrincipal.vue'),
    children: [
      { path: '', name: 'painel', component: () => import('../views/PainelView.vue') },
      { path: 'consultar', name: 'consultar', component: () => import('../views/ConsultarView.vue') },
      { path: 'ativos', name: 'ativos', component: () => import('../views/AtivosView.vue') },
      { path: 'ativos/novo', name: 'ativo-novo', component: () => import('../views/AtivoFormView.vue') },
      { path: 'ativos/:id', name: 'ativo', component: () => import('../views/AtivoDetalheView.vue'), props: true },
      { path: 'ativos/:id/editar', name: 'ativo-editar', component: () => import('../views/AtivoFormView.vue'), props: true },
      { path: 'ordens-servico', name: 'ordens', component: () => import('../views/OrdensServicoView.vue') },
      { path: 'movimentacoes', name: 'movimentacoes', component: () => import('../views/MovimentacoesView.vue') },
      { path: 'cadastros', name: 'cadastros', component: () => import('../views/CadastrosView.vue') },
      { path: 'usuarios', name: 'usuarios', component: () => import('../views/UsuariosView.vue') },
      { path: 'logs', name: 'logs', component: () => import('../views/LogsView.vue') },
    ],
  },
  { path: '/:caminho(.*)*', redirect: '/' },
]

const router = createRouter({ history: createWebHistory(), routes: rotas })

export default router
