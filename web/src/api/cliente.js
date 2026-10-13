import axios from 'axios'

const CHAVE = 'gestao-ativos:sessao'

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:8000/api',
  timeout: 15000,
})

export function lerSessao() {
  try {
    return JSON.parse(sessionStorage.getItem(CHAVE)) || null
  } catch {
    return null
  }
}

export function salvarSessao(sessao) {
  if (sessao) sessionStorage.setItem(CHAVE, JSON.stringify(sessao))
  else sessionStorage.removeItem(CHAVE)
}

// Envia o token JWT em toda requisição.
api.interceptors.request.use((config) => {
  const sessao = lerSessao()
  if (sessao?.access) config.headers.Authorization = `Bearer ${sessao.access}`
  return config
})

// Token expirado: tenta renovar uma vez; se não der, encerra a sessão.
let renovando = null
api.interceptors.response.use(
  (r) => r,
  async (erro) => {
    const original = erro.config
    const sessao = lerSessao()
    const ehLogin = original?.url?.includes('/auth/')
    if (erro.response?.status === 401 && sessao?.refresh && !original._repetida && !ehLogin) {
      original._repetida = true
      try {
        renovando ??= axios.post(`${api.defaults.baseURL}/auth/renovar/`, { refresh: sessao.refresh })
        const { data } = await renovando
        salvarSessao({ ...sessao, access: data.access })
        return api(original)
      } catch {
        salvarSessao(null)
        window.location.href = '/login?expirada=1'
      } finally {
        renovando = null
      }
    }
    return Promise.reject(erro)
  },
)

/** Converte a resposta de erro da API (DRF) em uma mensagem legível. */
export function mensagemDeErro(erro, padrao = 'Não foi possível concluir a operação.') {
  const r = erro?.response
  if (!r) return 'Sem conexão com o servidor. Verifique se a API está em execução.'
  if (r.status === 403) return r.data?.detail || 'Você não tem permissão para esta ação.'
  if (r.status === 429) return 'Muitas tentativas. Aguarde um minuto e tente de novo.'
  const d = r.data
  if (typeof d === 'string') return padrao
  if (d?.detail) return Array.isArray(d.detail) ? d.detail.join(' ') : d.detail
  if (d && typeof d === 'object') {
    const [campo, msgs] = Object.entries(d)[0] || []
    if (campo) return Array.isArray(msgs) ? msgs.join(' ') : String(msgs)
  }
  return padrao
}

/** Erros por campo, para exibir abaixo de cada input do formulário. */
export function errosPorCampo(erro) {
  const d = erro?.response?.data
  if (!d || typeof d !== 'object' || d.detail) return {}
  return Object.fromEntries(Object.entries(d).map(([k, v]) => [k, Array.isArray(v) ? v.join(' ') : String(v)]))
}
