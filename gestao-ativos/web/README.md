# Web — Painel administrativo (Vue)

Painel usado no computador para gerenciar os ativos. Consome a API Django.

**Tecnologias:** Vue 3 · Vite · Vue Router · Pinia · Axios

## Instalação e execução

```powershell
cd web
npm install
copy .env.exemplo .env     # ajuste VITE_API_URL se a API não estiver em localhost:8000
npm run dev
```

Acesse http://localhost:5173 (a API precisa estar rodando).

Build de produção: `npm run build` (gera a pasta `dist/`).

## Telas

| Tela | Perfil | Requisitos |
|---|---|---|
| Login | todos | RF01, RS01 |
| Painel (indicadores, manutenções previstas, ativos por local) | todos | B07 |
| Consultar ativo (código digitado ou leitor USB) | todos | RF03, RNF04 |
| Ativos — lista com busca e filtros | todos | RF04 |
| Ativo — ficha, etiqueta QR para impressão, histórico, movimentar, abrir/atualizar OS | todos | RF04, RF07–RF09 |
| Novo / editar ativo, inativar / reativar | admin | RF02, RF05, RF06 |
| Ordens de serviço | todos | RF08 |
| Movimentações | todos | RF07, RF09 |
| Categorias e locais, Usuários, Logs de auditoria | admin | RS02, RS04 |

## Observações de segurança

* O token JWT fica no `sessionStorage` (é apagado ao fechar a aba) e é renovado automaticamente.
* As rotas de administrador são bloqueadas no front, mas **a proteção real é feita pela API**.
