# Rastreabilidade — requisitos × implementação × evidência

Documento de apoio para as entregas E3/E4. Os testes citados ficam em `backend/ativos/tests.py`
(rodar com `python manage.py test`).

## Requisitos funcionais

| Req. | Descrição | Onde está | Evidência |
|---|---|---|---|
| RF01 | Login com credenciais | `POST /api/auth/login/` · tela de login (web e app) | `test_rf01_login_valido_retorna_tokens_e_perfil`, `test_rf01_login_invalido_e_recusado_e_registrado` |
| RF02 | Cadastrar ativo | `POST /api/ativos/` · web "Novo ativo" | `test_rf02_cadastrar_ativo` |
| RF03 | Consultar por QR Code / código de barras | `GET /api/ativos/codigo/{codigo}/` · app "Iniciar câmera" | `test_rf03_rf04_consulta_por_codigo` + demonstração no celular |
| RF04 | Consultar dados cadastrais | ficha do ativo (web e app) | `test_rf03_rf04_consulta_por_codigo` |
| RF05 | Editar ativo | `PATCH /api/ativos/{id}/` · web "Editar" | `test_rf05_editar_ativo` |
| RF06 | Inativar ativo mantendo histórico | `POST /api/ativos/{id}/inativar/` | `test_rf06_inativar_mantem_historico` |
| RF07 | Registrar movimentação | `POST /api/movimentacoes/` · web e app | `test_rf07_movimentacao_atualiza_local_e_registra_log` |
| RF08 | Abrir ordem de serviço | `POST /api/manutencoes/` · web e app | `test_rf08_ciclo_da_ordem_de_servico` |
| RF09 | Histórico de movimentações e OS | `GET /api/ativos/{id}/historico/` | `test_rf09_historico_unifica_movimentacoes_e_os` |
| RF10 | App consulta dados pela API | `mobile/lib/servicos/api.dart` | demonstração no celular |

## Requisitos não funcionais

| Req. | Como foi atendido | Como verificar |
|---|---|---|
| RNF01 | Painel web Vue (Chrome/Edge) | abrir http://localhost:5173, fazer login, cadastrar e consultar |
| RNF02 | `mobile_scanner` lê QR, Code 128 e EAN | ler a etiqueta impressa pelo web com o celular |
| RNF03 | Dados no PostgreSQL | cadastrar, parar a API, iniciar de novo e consultar |
| RNF04 | Campo "Código do ativo" no app e na tela Consultar do web; botão "digitar manualmente" se a câmera falhar | consultar sem usar a câmera |
| RNF05 | READMEs da raiz, `backend/`, `web/`, `mobile/` | outro integrante segue os passos |

## Requisitos de segurança

| Req. | Controle | Evidência |
|---|---|---|
| RS01 | Toda rota exige JWT (`DEFAULT_PERMISSION_CLASSES`) | `test_rs01_rota_protegida_sem_login_e_bloqueada` |
| RS02 | `EhAdmin` / `AdminOuSomenteLeitura` na API | `test_rs02_usuario_comum_nao_cadastra_ativo`, `test_rs02_usuario_comum_nao_edita_nem_inativa` |
| RS03 | Validação nos serializers + CHECKs no banco | `test_rs03_cadastro_invalido_e_rejeitado`, `test_rs03_custo_negativo_rejeitado` |
| RS04 | Tabela `log_auditoria`, sanitização de chaves sensíveis | `test_rs04_log_nao_guarda_senha_nem_token` + tela "Logs de auditoria" |
| RS05 | `scripts/backup.ps1` e `scripts/restaurar.ps1` (pg_dump / pg_restore) | apagar movimentações → restaurar → contagem volta (testado em 13/10/2026) |

## Hipótese H03 (teste de mau uso)

1. Entrar no app/web como `carlos.m@gestao.local` (perfil usuário).
2. Chamar `PATCH /api/ativos/1/` pelo Swagger com o token dele → resposta **403**.
3. Entrar como admin → Logs de auditoria → filtrar "Acesso negado": a tentativa aparece com usuário, rota e IP.
