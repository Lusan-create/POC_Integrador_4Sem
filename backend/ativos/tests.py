"""
Testes automatizados da API — evidências dos requisitos RF, RNF e RS.
Rodar:  python manage.py test
"""
from datetime import date

from django.core.cache import cache
from django.test import TestCase
from rest_framework.test import APIClient

from auditoria.models import Acao, LogAuditoria
from contas.models import Cargo, Usuario

from .models import Ativo, Categoria, Localizacao, Manutencao, StatusAtivo


class BaseAPITest(TestCase):
    @classmethod
    def setUpTestData(cls):
        cls.admin = Usuario.objects.create_user("admin@teste.com", "SenhaForte#1", nome="Admin Teste", cargo=Cargo.ADMIN)
        cls.user = Usuario.objects.create_user("user@teste.com", "SenhaForte#2", nome="Usuário Teste")
        cls.cat = Categoria.objects.create(nome="Notebook")
        cls.lab1 = Localizacao.objects.create(nome="Lab 1")
        cls.lab2 = Localizacao.objects.create(nome="Lab 2")
        cls.ativo = Ativo.objects.create(
            identificacao="PT-000324", nome="Notebook Dell", categoria=cls.cat,
            localizacao=cls.lab1, responsavel=cls.user, status=StatusAtivo.EM_USO,
        )

    def setUp(self):
        cache.clear()  # zera o limitador de tentativas de login entre testes
        self.api = APIClient()

    def logar(self, usuario):
        self.api.force_authenticate(usuario)


class AutenticacaoTests(BaseAPITest):
    def test_rf01_login_valido_retorna_tokens_e_perfil(self):
        r = self.api.post("/api/auth/login/", {"email": "ADMIN@teste.com", "password": "SenhaForte#1"})
        self.assertEqual(r.status_code, 200)
        self.assertIn("access", r.data)
        self.assertEqual(r.data["usuario"]["cargo"], "admin")
        self.assertTrue(LogAuditoria.objects.filter(acao=Acao.LOGIN, usuario=self.admin).exists())

    def test_rf01_login_invalido_e_recusado_e_registrado(self):
        r = self.api.post("/api/auth/login/", {"email": "admin@teste.com", "password": "errada"})
        self.assertEqual(r.status_code, 401)
        log = LogAuditoria.objects.get(acao=Acao.LOGIN_FALHA)
        self.assertEqual(log.usuario_email, "admin@teste.com")

    def test_rs01_rota_protegida_sem_login_e_bloqueada(self):
        for rota in ["/api/ativos/", "/api/ativos/codigo/PT-000324/", "/api/movimentacoes/", "/api/painel/"]:
            self.assertEqual(self.api.get(rota).status_code, 401, rota)

    def test_rs01_token_jwt_permite_acesso(self):
        r = self.api.post("/api/auth/login/", {"email": "user@teste.com", "password": "SenhaForte#2"})
        self.api.credentials(HTTP_AUTHORIZATION=f"Bearer {r.data['access']}")
        self.assertEqual(self.api.get("/api/ativos/").status_code, 200)

    def test_usuario_excluido_nao_consegue_logar(self):
        from django.utils import timezone
        self.user.deletado_em = timezone.now()
        self.user.save()
        r = self.api.post("/api/auth/login/", {"email": "user@teste.com", "password": "SenhaForte#2"})
        self.assertEqual(r.status_code, 401)

    def test_limite_de_tentativas_de_login(self):
        for _ in range(10):
            self.api.post("/api/auth/login/", {"email": "x@teste.com", "password": "x"})
        r = self.api.post("/api/auth/login/", {"email": "x@teste.com", "password": "x"})
        self.assertEqual(r.status_code, 429)


class PermissaoTests(BaseAPITest):
    def test_rs02_usuario_comum_nao_cadastra_ativo(self):
        self.logar(self.user)
        r = self.api.post("/api/ativos/", {"identificacao": "PT-1", "nome": "X", "categoria_id": self.cat.id,
                                           "localizacao_id": self.lab1.id})
        self.assertEqual(r.status_code, 403)
        self.assertTrue(LogAuditoria.objects.filter(acao=Acao.ACESSO_NEGADO, usuario=self.user).exists())

    def test_rs02_usuario_comum_nao_edita_nem_inativa(self):
        self.logar(self.user)
        self.assertEqual(self.api.patch(f"/api/ativos/{self.ativo.id}/", {"nome": "Hack"}).status_code, 403)
        self.assertEqual(self.api.post(f"/api/ativos/{self.ativo.id}/inativar/").status_code, 403)
        self.assertEqual(self.api.get("/api/usuarios/").status_code, 403)
        self.assertEqual(self.api.get("/api/logs/").status_code, 403)

    def test_rs02_usuario_comum_consulta_movimenta_e_abre_os(self):
        self.logar(self.user)
        self.assertEqual(self.api.get(f"/api/ativos/{self.ativo.id}/").status_code, 200)
        r = self.api.post("/api/movimentacoes/", {"ativo_id": self.ativo.id, "destino_id": self.lab2.id})
        self.assertEqual(r.status_code, 201)
        r = self.api.post("/api/manutencoes/", {"ativo_id": self.ativo.id, "descricao": "Tela piscando"})
        self.assertEqual(r.status_code, 201)


class AtivoTests(BaseAPITest):
    def setUp(self):
        super().setUp()
        self.logar(self.admin)

    def test_rf02_cadastrar_ativo(self):
        r = self.api.post("/api/ativos/", {
            "identificacao": "pt-000999", "nome": "Monitor LG", "categoria_id": self.cat.id,
            "localizacao_id": self.lab1.id,
        })
        self.assertEqual(r.status_code, 201, r.data)
        self.assertEqual(r.data["identificacao"], "PT-000999")
        self.assertEqual(r.data["localizacao"]["nome"], "Lab 1")
        self.assertTrue(LogAuditoria.objects.filter(acao=Acao.CRIAR, entidade="ativo").exists())

    def test_rs03_cadastro_invalido_e_rejeitado(self):
        r = self.api.post("/api/ativos/", {"identificacao": "", "nome": ""})
        self.assertEqual(r.status_code, 400)
        for campo in ["identificacao", "nome", "categoria_id", "localizacao_id"]:
            self.assertIn(campo, r.data)
        r = self.api.post("/api/ativos/", {"identificacao": "PT-000324", "nome": "Dup",
                                           "categoria_id": self.cat.id, "localizacao_id": self.lab1.id})
        self.assertEqual(r.status_code, 400)
        r = self.api.post("/api/ativos/", {"identificacao": "<script>", "nome": "X",
                                           "categoria_id": self.cat.id, "localizacao_id": self.lab1.id})
        self.assertEqual(r.status_code, 400)

    def test_rf03_rf04_consulta_por_codigo(self):
        r = self.api.get("/api/ativos/codigo/pt-000324/")
        self.assertEqual(r.status_code, 200)
        for campo in ["identificacao", "nome", "categoria", "localizacao", "responsavel", "status_exibicao"]:
            self.assertIn(campo, r.data)
        self.assertEqual(self.api.get("/api/ativos/codigo/NAO-EXISTE/").status_code, 404)

    def test_rf05_editar_ativo(self):
        r = self.api.patch(f"/api/ativos/{self.ativo.id}/", {"nome": "Notebook Dell Latitude"})
        self.assertEqual(r.status_code, 200)
        self.ativo.refresh_from_db()
        self.assertEqual(self.ativo.nome, "Notebook Dell Latitude")

    def test_rf06_inativar_mantem_historico(self):
        self.api.post("/api/movimentacoes/", {"ativo_id": self.ativo.id, "destino_id": self.lab2.id})
        r = self.api.post(f"/api/ativos/{self.ativo.id}/inativar/")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data["status"], "inativo")
        hist = self.api.get(f"/api/ativos/{self.ativo.id}/historico/")
        self.assertEqual(len(hist.data["eventos"]), 1)
        # ativo inativo não pode ser movimentado
        r = self.api.post("/api/movimentacoes/", {"ativo_id": self.ativo.id, "destino_id": self.lab1.id})
        self.assertEqual(r.status_code, 400)

    def test_excluir_ativo_e_logico(self):
        self.assertEqual(self.api.delete(f"/api/ativos/{self.ativo.id}/").status_code, 204)
        self.assertFalse(Ativo.objects.filter(pk=self.ativo.pk).exists())
        self.assertTrue(Ativo.todos.filter(pk=self.ativo.pk).exists())

    def test_categoria_em_uso_nao_pode_ser_excluida(self):
        self.assertEqual(self.api.delete(f"/api/categorias/{self.cat.id}/").status_code, 409)

    def test_qrcode_png(self):
        r = self.api.get(f"/api/ativos/{self.ativo.id}/qrcode/")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r["Content-Type"], "image/png")


class MovimentacaoEOSTests(BaseAPITest):
    def setUp(self):
        super().setUp()
        self.logar(self.user)

    def test_rf07_movimentacao_atualiza_local_e_registra_log(self):
        r = self.api.post("/api/movimentacoes/", {"ativo_id": self.ativo.id, "destino_id": self.lab2.id,
                                                  "observacao": "Aula prática"})
        self.assertEqual(r.status_code, 201, r.data)
        self.assertEqual(r.data["origem"]["nome"], "Lab 1")
        self.ativo.refresh_from_db()
        self.assertEqual(self.ativo.localizacao, self.lab2)
        self.assertTrue(LogAuditoria.objects.filter(acao=Acao.MOVIMENTAR, usuario=self.user).exists())

    def test_rf07_movimentacao_para_o_mesmo_local_e_rejeitada(self):
        r = self.api.post("/api/movimentacoes/", {"ativo_id": self.ativo.id, "destino_id": self.lab1.id})
        self.assertEqual(r.status_code, 400)

    def test_rf08_ciclo_da_ordem_de_servico(self):
        r = self.api.post("/api/manutencoes/", {"ativo_id": self.ativo.id, "descricao": "Não liga"})
        self.assertEqual(r.status_code, 201, r.data)
        os_id = r.data["id"]
        self.ativo.refresh_from_db()
        self.assertEqual(self.ativo.status, StatusAtivo.EM_MANUTENCAO)

        # concluir sem data é rejeitado
        r = self.api.patch(f"/api/manutencoes/{os_id}/", {"status": "concluida"})
        self.assertEqual(r.status_code, 400)

        r = self.api.patch(f"/api/manutencoes/{os_id}/", {
            "status": "concluida", "realizada_em": "2026-10-10", "proxima_prevista": "2027-04-10", "custo": "150.00",
        })
        self.assertEqual(r.status_code, 200, r.data)
        self.ativo.refresh_from_db()
        self.assertEqual(self.ativo.status, StatusAtivo.DISPONIVEL)
        # trigger do banco atualizou as datas do ativo
        self.assertEqual(self.ativo.ultima_manutencao, date(2026, 10, 10))
        self.assertEqual(self.ativo.proxima_manutencao, date(2027, 4, 10))

        # OS encerrada não pode ser reaberta
        r = self.api.patch(f"/api/manutencoes/{os_id}/", {"status": "aberta"})
        self.assertEqual(r.status_code, 400)

    def test_rs03_custo_negativo_rejeitado(self):
        r = self.api.post("/api/manutencoes/", {"ativo_id": self.ativo.id, "descricao": "x", "custo": "-1"})
        self.assertEqual(r.status_code, 400)

    def test_usuario_comum_nao_exclui_os(self):
        os_ = Manutencao.objects.create(ativo=self.ativo, descricao="x")
        self.assertEqual(self.api.delete(f"/api/manutencoes/{os_.id}/").status_code, 403)

    def test_rf09_historico_unifica_movimentacoes_e_os(self):
        self.api.post("/api/movimentacoes/", {"ativo_id": self.ativo.id, "destino_id": self.lab2.id})
        self.api.post("/api/manutencoes/", {"ativo_id": self.ativo.id, "descricao": "Revisão"})
        r = self.api.get(f"/api/ativos/{self.ativo.id}/historico/")
        self.assertEqual(r.status_code, 200)
        self.assertEqual({e["tipo"] for e in r.data["eventos"]}, {"movimentacao", "manutencao"})


class AuditoriaTests(BaseAPITest):
    def test_rs04_log_nao_guarda_senha_nem_token(self):
        self.logar(self.admin)
        self.api.post("/api/usuarios/", {"nome": "Novo Usuário", "email": "novo@teste.com",
                                         "senha": "OutraSenha#9", "cargo": "user"})
        self.api.patch(f"/api/usuarios/{self.user.id}/", {"senha": "TrocaSenha#7"})
        self.api.post("/api/auth/login/", {"email": "admin@teste.com", "password": "SenhaForte#1"})
        for log in LogAuditoria.objects.all():
            texto = f"{log.descricao} {log.detalhes}"
            for segredo in ["OutraSenha#9", "TrocaSenha#7", "SenhaForte#1", "pbkdf2"]:
                self.assertNotIn(segredo, texto)

    def test_admin_nao_exclui_a_si_mesmo(self):
        self.logar(self.admin)
        self.assertEqual(self.api.delete(f"/api/usuarios/{self.admin.id}/").status_code, 400)

    def test_senha_fraca_rejeitada(self):
        self.logar(self.admin)
        r = self.api.post("/api/usuarios/", {"nome": "Fulano", "email": "f@teste.com", "senha": "123", "cargo": "user"})
        self.assertEqual(r.status_code, 400)
        self.assertIn("senha", r.data)
