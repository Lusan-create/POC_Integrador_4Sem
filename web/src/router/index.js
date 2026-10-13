import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const rotas = [
  { path: '/login', name: 'login', component: () => import('../views/LoginView.vue'), meta: { publica: true } },
  {
    path: '/',
    component: () => import('../components/LayoutPrincipal.vue'),
    children: [
      { path: '', name: 'painel', component: () => import('../views/PainelView.vue') },
      { path: 'consultar', name: 'consultar', component: () => import('../views/ConsultarView.vue') },
      { path: 'ativos', name: 'ativos', component: () => import('../views/AtivosView.vue') },
      { path: 'ativos/novo', name: 'ativo-novo', component: () => import('../views/AtivoFormView.vue'), meta: { admin: true } },
      { path: 'ativos/:id', name: 'ativo', component: () => import('../views/AtivoDetalheView.vue'), props: true },
      { path: 'ativos/:id/editar', name: 'ativo-editar', component: () => import('../views/AtivoFormView.vue'), props: true, meta: { admin: true } },
      { path: 'ordens-servico', name: 'ordens', component: () => import('../views/OrdensServicoView.vue') },
      { path: 'movimentacoes', name: 'movimentacoes', component: () => import('../views/MovimentacoesView.vue') },
      { path: 'cadastros', name: 'cadastros', component: () => import('../views/CadastrosView.vue'), meta: { admin: true } },
      { path: 'usuarios', name: 'usuarios', component: () => import('../views/UsuariosView.vue'), meta: { admin: true } },
      { path: 'logs', name: 'logs', component: () => import('../views/LogsView.vue'), meta: { admin: true } },
    ],
  },
  { path: '/:caminho(.*)*', redirect: '/' },
]

const router = createRouter({ history: createWebHistory(), routes: rotas })

// Protege as rotas no front-end (a API também valida tudo — RS01/RS02).
router.beforeEach((to) => {
  const auth = useAuthStore()
  if (!to.meta.publica && !auth.autenticado) return { name: 'login', query: { voltar: to.fullPath } }
  if (to.name === 'login' && auth.autenticado) return { name: 'painel' }
  if (to.meta.admin && !auth.ehAdmin) return { name: 'painel' }
})

export default router
