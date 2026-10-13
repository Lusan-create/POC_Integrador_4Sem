# Sistema de Gestão de Ativos — MVP

Projeto Integrador IV — SENAI · Turma CSTADS125N4
Grupo: Luiz Santana, João Pedro Duarte, Murilo Andrey Muloque e Isaque Costa

Sistema para cadastrar, identificar (QR Code / código de barras) e rastrear ativos de laboratórios:
consulta do ativo, registro de **movimentação** entre locais, **ordens de serviço** de manutenção e
**histórico** completo — com controle de acesso por perfil e log de auditoria.

## Estrutura (três projetos independentes)

```
gestao-ativos/
├── backend/   API REST — Python, Django, Django REST Framework, JWT, PostgreSQL
├── web/       Painel web — Vue 3, Vite, Vue Router, Pinia
├── mobile/    Aplicativo — Flutter (Android e Chrome)
└── docs/      Contrato da API (OpenAPI), rastreabilidade de requisitos
```

O **web** e o **mobile** nunca acessam o banco: comunicam-se apenas com a **API** via HTTP/JSON,
autenticando-se com token JWT.

```
 [App Flutter]   [Painel Vue]
        \             /
         HTTP + JSON (JWT)
               │
      [API Django REST]
               │
        [PostgreSQL 16]
```

## Como executar (resumo)

Pré-requisitos: Python 3.12, Node 22, PostgreSQL 16, Flutter 3.x com Android SDK.

| Parte | Comando | Endereço |
|---|---|---|
| API | `cd backend` → `.venv\Scripts\activate` → `python manage.py runserver 0.0.0.0:8000` | http://localhost:8000/api/docs/ |
| Web | `cd web` → `npm install` → `npm run dev` | http://localhost:5173 |
| Mobile | `cd mobile` → `flutter run` (celular no USB) ou `flutter run -d chrome` | — |

Instruções completas em cada pasta: [backend/README.md](backend/README.md),
[web/README.md](web/README.md), [mobile/README.md](mobile/README.md).

## Usuários de demonstração (dados fictícios)

Criados com `python manage.py popular_demo`:

| Perfil | E-mail | Senha |
|---|---|---|
| Administrador | admin@gestao.local | Admin@2026 |
| Usuário (técnico) | carlos.m@gestao.local | Tecnico@2026 |
| Usuário | ana.r@gestao.local | Usuario@2026 |

Código de ativo para testar a consulta: **PT-000324**.

## Perfis de acesso (decisão D02)

| Ação | Administrador | Usuário |
|---|:-:|:-:|
| Consultar ativos, histórico, painel | ✅ | ✅ |
| Registrar movimentação | ✅ | ✅ |
| Abrir / atualizar ordem de serviço | ✅ | ✅ |
| Cadastrar, editar, inativar e excluir ativos | ✅ | ❌ |
| Categorias, locais e usuários | ✅ | ❌ |
| Logs de auditoria, excluir OS | ✅ | ❌ |
