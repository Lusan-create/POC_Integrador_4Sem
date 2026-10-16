# Sistema de Gestão de Ativos — MVP

Projeto Integrador IV — SENAI · Turma CSTADS125N4
Grupo: Luiz Santana, João Pedro Duarte, Murilo Andrey Muloque e Isaque Costa

Sistema para cadastrar, identificar (QR Code / código de barras) e rastrear ativos de laboratórios:
consulta do ativo, registro de **movimentação** entre locais, **ordens de serviço** de manutenção e
**histórico** completo — com controle de acesso por perfil e log de auditoria.

## Estrutura (três projetos independentes)

```
POC_Integrador_4Sem/
├── src/
│   ├── backend/   API REST — Python, Django, Django REST Framework, JWT, PostgreSQL
│   ├── web/       Painel web — Vue 3, Vite, Vue Router
│   └── mobile/    Aplicativo — Flutter (Android e Chrome)
└── docs/          Contrato da API (OpenAPI), rastreabilidade de requisitos, entregas
```

O **web** e o **mobile** nunca acessam o banco: comunicam-se apenas com a **API** via HTTP/JSON.
Por ser uma POC, web e mobile **não têm login**: a API mantém o login JWT (`/api/auth/login/`), mas
aceita as demais rotas sem token.

```
 [App Flutter]   [Painel Vue]
        \             /
         HTTP + JSON
               │
      [API Django REST]
               │
        [PostgreSQL 16]
```

## Como iniciar o projeto

### Pré-requisitos

| Ferramenta | Versão | Usada em |
|---|---|---|
| Python | 3.12 ou 3.13 | backend |
| Docker Desktop | qualquer recente | banco de dados (PostgreSQL 16 em contêiner) |
| Node.js | 22 | web |
| Flutter (com Android SDK / Android Studio) | 3.x | mobile |

A ordem é sempre: **banco → API → web e/ou mobile**. O web e o mobile não funcionam sem a API rodando.

### 1. Banco de dados (Docker)

O PostgreSQL 16 roda em um contêiner Docker definido em `src/backend/docker-compose.yml`. Nome do banco,
usuário, senha e porta são lidos do `src/backend/.env` (os mesmos usados pela API), então não é preciso
instalar o PostgreSQL nem criar usuário manualmente.

Com o Docker Desktop aberto:

```powershell
cd src\backend
copy .env.exemplo .env          # só na primeira vez; edite DB_SENHA e DJANGO_SECRET_KEY
docker compose up -d            # sobe o banco (os dados ficam no volume "dados_banco")
```

Outros comandos úteis: `docker compose ps` (situação), `docker compose stop` (parar),
`docker compose down -v` (**apaga** o banco para começar do zero).

> Se a porta 5432 já estiver em uso por outro PostgreSQL, troque `DB_PORTA` no `.env` (ex.: 5433) e
> rode `docker compose up -d` de novo.

### 2. API (backend)

Primeira vez:

```powershell
cd src\backend
py -3.12 -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate        # cria as tabelas
python manage.py popular_demo   # cria usuários e ativos de demonstração
```

Nas próximas vezes:

```powershell
cd src\backend
.venv\Scripts\activate
python manage.py runserver 0.0.0.0:8000
```

Confira em http://localhost:8000/api/docs/ (documentação interativa da API).

### 3. Painel web

Em outro terminal, com a API rodando:

```powershell
cd src\web
npm install                     # só na primeira vez
copy .env.exemplo .env          # só na primeira vez; ajuste VITE_API_URL se a API não estiver em localhost:8000
npm run dev
```

Acesse http://localhost:5173 e entre com um dos usuários de demonstração abaixo.

### 4. Aplicativo mobile

Em outro terminal, com a API rodando:

```powershell
cd src\mobile
flutter pub get
flutter run -d chrome --dart-define=API_URL=http://localhost:8000/api      # no navegador
flutter run --dart-define=API_URL=http://SEU_IP:8000/api                   # no celular Android pelo USB
```

Para usar no celular:

* celular e PC na **mesma rede Wi-Fi**; descubra o IP do PC com `ipconfig`;
* com `DJANGO_DEBUG=true` a API aceita qualquer IP; só libere a porta 8000 no Firewall do Windows;
* o endereço da API também pode ser trocado dentro do app, pelo menu (☰) → "Endereço do servidor".

> Se o build Android falhar com *"Could not close incremental caches"* / *"different roots"*, é porque o
> cache de pacotes do Flutter (C:) e o projeto (D:) estão em discos diferentes. O
> `src\mobile\android\gradle.properties` já tem `kotlin.incremental=false` para isso; se o Flutter
> apagar essa linha, coloque-a de volta e rode `flutter clean`.

### 5. Testes

| Parte | Comando |
|---|---|
| API | `cd src\backend` → `python manage.py test` |
| Web | `cd src\web` → `npm run build` |
| Mobile | `cd src\mobile` → `flutter analyze` e `flutter test` |

Mais detalhes em cada pasta: [src/backend/README.md](src/backend/README.md),
[src/web/README.md](src/web/README.md), [src/mobile/README.md](src/mobile/README.md).

## Dados de demonstração (fictícios)

Criados com `python manage.py popular_demo`.

Código de ativo para testar a consulta: **PT-000324**.

## Perfis de acesso

Sem login na POC, web e mobile têm acesso a todas as funções. O cargo (Administrador/Usuário) segue
no cadastro de usuários apenas como informação.
