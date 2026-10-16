# Back-end — API REST (Django)

API que concentra as regras de negócio e o acesso ao banco PostgreSQL. É consumida pelo painel web (Vue)
e pelo aplicativo (Flutter).

**Tecnologias:** Python 3.12 · Django 5.1 · Django REST Framework · SimpleJWT · drf-spectacular (Swagger) ·
PostgreSQL 16 (Docker) · psycopg 3

## 1. Instalação

```powershell
cd backend
py -3.12 -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.exemplo .env      # depois edite o .env
```

### Banco de dados (Docker)

O PostgreSQL 16 roda em contêiner (`docker-compose.yml` nesta pasta), com nome do banco, usuário, senha e
porta lidos do `.env`. Com o Docker Desktop aberto:

```powershell
docker compose up -d
```

### Criar as tabelas e os dados de demonstração

```powershell
python manage.py migrate
python manage.py popular_demo
```

## 2. Executar

```powershell
python manage.py runserver 0.0.0.0:8000
```

* Documentação interativa (contrato da API): http://localhost:8000/api/docs/
* Admin do Django: http://localhost:8000/admin/ (entrar com o usuário administrador)

> `0.0.0.0` permite que o celular acesse a API pelo IP do computador. Com `DJANGO_DEBUG=true`
> qualquer IP é aceito; libere a porta 8000 no Firewall do Windows.

## 3. Testes automatizados

```powershell
python manage.py test
```

26 testes cobrem login, bloqueio sem autenticação (RS01), permissões por perfil (RS02), validação de
dados (RS03), logs sem senha/token (RS04), cadastro/consulta/edição/inativação (RF02–RF06),
movimentação (RF07), ordens de serviço (RF08) e histórico (RF09).

## 4. Backup e restauração (RS05)

Os scripts rodam `pg_dump`/`pg_restore` dentro do contêiner do banco (ele precisa estar rodando).

```powershell
.\scripts\backup.ps1                         # gera backend\backups\gestao_ativos_AAAAMMDD_HHMMSS.dump
.\scripts\restaurar.ps1                      # restaura o backup mais recente
.\scripts\restaurar.ps1 -Arquivo caminho.dump
```

Se o PowerShell bloquear scripts: `powershell -ExecutionPolicy Bypass -File .\scripts\backup.ps1`.

## 5. Principais rotas

> **POC:** o login JWT continua disponível, mas todas as rotas aceitam requisições sem token
> (web e mobile não fazem login). A coluna "Perfil" descreve o desenho original.

| Método | Rota | Descrição | Perfil |
|---|---|---|---|
| POST | `/api/auth/login/` | Login (e-mail + senha) → tokens JWT | público |
| POST | `/api/auth/renovar/` | Renova o token de acesso | público |
| GET | `/api/auth/eu/` | Dados do usuário logado | todos |
| GET | `/api/painel/` | Indicadores do painel | todos |
| GET/POST | `/api/ativos/` | Lista (filtros/busca) / cadastra | todos / admin |
| GET/PATCH/DELETE | `/api/ativos/{id}/` | Consulta / edita / exclui (lógica) | todos / admin |
| GET | `/api/ativos/codigo/{codigo}/` | Consulta pelo QR Code ou código digitado | todos |
| POST | `/api/ativos/{id}/inativar/` · `/reativar/` | Inativação | admin |
| GET | `/api/ativos/{id}/historico/` | Movimentações + OS | todos |
| GET | `/api/ativos/{id}/qrcode/` | Etiqueta QR (PNG) | todos |
| GET/POST | `/api/movimentacoes/` | Lista / registra movimentação | todos |
| GET/POST/PATCH | `/api/manutencoes/` | Ordens de serviço | todos |
| CRUD | `/api/categorias/`, `/api/localizacoes/` | Cadastros auxiliares | leitura: todos · escrita: admin |
| CRUD | `/api/usuarios/` | Usuários | admin |
| GET | `/api/logs/` | Logs de auditoria | admin |

## 6. Modelo de dados

Segue o DER "3.2 Modelo de dados", com as extensões aprovadas pelo grupo:

* **ATIVO**: novos campos `nome` e `status` (disponível, em uso, em manutenção, inativo);
* **MANUTENCAO** também representa a **Ordem de Serviço**: novos campos `tipo`, `status`, `aberta_em`;
  `realizada_em` passou a ser opcional (preenchido ao concluir);
* nova tabela **MOVIMENTACAO** (ativo, origem, destino, observação, registrado_por, realizada_em);
* nova tabela **LOG_AUDITORIA** (usuário, ação, entidade, descrição, IP, data).

Objetos de banco do DER implementados na migração `ativos/0002_triggers_e_view.py`:
trigger de `atualizado_em`, trigger que atualiza última/próxima manutenção do ativo ao concluir uma OS,
e a view `vw_ativo`. Os CHECKs e ON DELETE RESTRICT / SET NULL estão nos models.

## 7. Segurança implementada

* Senhas com hash PBKDF2 (coluna `senha_hash`), política mínima de senha (8+ caracteres, não comum, não numérica).
* JWT com expiração (60 min) e renovação; usuário excluído perde o acesso imediatamente.
* Limite de 10 tentativas de login por minuto (HTTP 429).
* Permissões por perfil validadas **na API** (o front só esconde botões).
* Tentativas negadas, falhas de login e todas as alterações vão para o log; senha/token nunca são registrados.
* Exclusões são lógicas (`deletado_em`) para manter o histórico.
* Chave secreta e senha do banco apenas no `.env` (fora do Git).
