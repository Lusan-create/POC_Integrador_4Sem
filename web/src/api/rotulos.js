// Textos e cores dos status, compartilhados entre as telas.
export const STATUS_ATIVO = {
  disponivel: { texto: 'Disponível', cor: 'verde' },
  em_uso: { texto: 'Em uso', cor: 'azul' },
  em_manutencao: { texto: 'Em manutenção', cor: 'laranja' },
  inativo: { texto: 'Inativo', cor: 'cinza' },
}

export const STATUS_OS = {
  aberta: { texto: 'Aberta', cor: 'laranja' },
  em_andamento: { texto: 'Em andamento', cor: 'azul' },
  concluida: { texto: 'Concluída', cor: 'verde' },
  cancelada: { texto: 'Cancelada', cor: 'cinza' },
}

export const TIPO_OS = { corretiva: 'Corretiva', preventiva: 'Preventiva' }

export function dataHora(valor) {
  if (!valor) return '—'
  return new Date(valor).toLocaleString('pt-BR', { dateStyle: 'short', timeStyle: 'short' })
}

export function data(valor) {
  if (!valor) return '—'
  const [a, m, d] = String(valor).slice(0, 10).split('-')
  return `${d}/${m}/${a}`
}

export function moeda(valor) {
  if (valor === null || valor === undefined || valor === '') return '—'
  return Number(valor).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' })
}

export function hojeISO() {
  const d = new Date()
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 10)
}
