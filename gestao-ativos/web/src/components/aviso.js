import { reactive } from 'vue'

// Pequeno sistema de avisos (toasts) usado por todas as telas.
export const avisos = reactive({ lista: [] })
let seq = 0

export function avisar(texto, tipo = 'sucesso') {
  const id = ++seq
  avisos.lista.push({ id, texto, tipo })
  setTimeout(() => {
    avisos.lista = avisos.lista.filter((a) => a.id !== id)
  }, 4000)
}
