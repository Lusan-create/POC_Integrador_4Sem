# Contexto do projeto (para o Claude Code)

MVP do Projeto Integrador IV (SENAI, turma CSTADS125N4): Sistema de Gestão de Ativos.
Grupo: Luiz Santana, João Pedro Duarte, Murilo Andrey Muloque, Isaque Costa.

## Regras definidas pelo grupo
- Três projetos **separados** (exigência do professor): `backend/` (Django + DRF + JWT + PostgreSQL 16),
  `web/` (Vue 3 + Vite + Pinia), `mobile/` (Flutter — obrigatório). Web e mobile só falam com a API.
- **Tudo em português**: código (models/campos iguais ao DER), interface, docs e mensagens de commit.
- Sem Realidade Aumentada nesta etapa.
- Login por e-mail. Perfis: `admin` faz tudo; `user` consulta, registra movimentação, abre/atualiza OS, vê histórico.
- MANUTENCAO também é a Ordem de Serviço. Tabelas extras aprovadas: MOVIMENTACAO, LOG_AUDITORIA; `status` no ATIVO.
- Prazos: E4 05/11/2026 (segurança, testes, evidências) · E5 03/12/2026 (pacote final e apresentação).

## Como trabalhar neste repositório
- Não pedir confirmação para instalar, rodar comandos ou criar arquivos; perguntar só decisões de definição
  (escopo, regra de negócio, tecnologia).
- Backend: `backend\.venv\Scripts\python manage.py test` deve continuar passando.
- Mobile: `C:\dev\flutter\bin\flutter.bat analyze` sem problemas. Java do Gradle: `C:\Program Files\Android\Android Studio\jbr`.
- Web: `npx vite build` deve compilar.
- Evidências de requisitos em `docs/rastreabilidade.md`; atualizar ao mudar comportamento.
