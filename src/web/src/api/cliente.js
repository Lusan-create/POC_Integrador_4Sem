import axios from 'axios'

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:8000/api',
  timeout: 15000,
})

/** Converte a resposta de erro da API (DRF) em uma mensagem legível. */
export function mensagemDeErro(erro, padrao = 'Não foi possível concluir a operação.') {
  const r = erro?.response
  if (!r) return 'Sem conexão com o servidor. Verifique se a API está em execução.'
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
