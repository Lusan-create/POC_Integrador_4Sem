import { defineStore } from 'pinia'
import { api, lerSessao, salvarSessao } from '../api/cliente'

export const useAuthStore = defineStore('auth', {
  state: () => ({ sessao: lerSessao() }),
  getters: {
    autenticado: (s) => !!s.sessao?.access,
    usuario: (s) => s.sessao?.usuario || null,
    ehAdmin: (s) => s.sessao?.usuario?.cargo === 'admin',
  },
  actions: {
    async entrar(email, senha) {
      const { data } = await api.post('/auth/login/', { email, password: senha })
      this.sessao = { access: data.access, refresh: data.refresh, usuario: data.usuario }
      salvarSessao(this.sessao)
    },
    sair() {
      this.sessao = null
      salvarSessao(null)
    },
  },
})
