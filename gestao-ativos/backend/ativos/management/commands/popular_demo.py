"""
Cria dados FICTÍCIOS para demonstração (premissa RP04).

Uso:  python manage.py popular_demo          (não duplica se já existir)
      python manage.py popular_demo --limpar (apaga ativos/OS/movimentações/logs antes)
"""
from datetime import date, timedelta
from decimal import Decimal

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from ativos.models import (
    Ativo, Categoria, Localizacao, Manutencao, Movimentacao, StatusAtivo, StatusOS, TipoManutencao,
)
from auditoria.models import LogAuditoria
from contas.models import Cargo, Usuario

USUARIOS = [
    ("Administrador Demo", "admin@gestao.local", "Admin@2026", Cargo.ADMIN),
    ("Carlos Mendes", "carlos.m@gestao.local", "Tecnico@2026", Cargo.USER),
    ("Ana Ribeiro", "ana.r@gestao.local", "Usuario@2026", Cargo.USER),
]

CATEGORIAS = ["Notebook", "Desktop", "Monitor", "Projetor", "Impressora 3D", "Bancada eletrônica", "Rede"]

LOCAIS = [
    ("Lab. Info. 1", "Laboratório de Informática 1 — bloco A"),
    ("Lab. Info. 2", "Laboratório de Informática 2 — bloco A"),
    ("Lab. Eletrônica", "Laboratório de Eletrônica — bloco B"),
    ("Lab. Maker", "Espaço maker — bloco B"),
    ("Almoxarifado", "Depósito de equipamentos"),
    ("Sala de Manutenção", "Oficina de TI"),
]

# patrimônio, nome, categoria, local, responsável (e-mail), status, próxima manutenção (dias)
ATIVOS = [
    ("PT-000324", "Notebook Dell Latitude 5420", "Notebook", "Lab. Info. 1", "carlos.m@gestao.local", StatusAtivo.EM_USO, 60),
    ("PT-000325", "Notebook Dell Latitude 5420", "Notebook", "Lab. Info. 1", "carlos.m@gestao.local", StatusAtivo.EM_USO, 60),
    ("PT-000326", "Notebook Lenovo ThinkPad E14", "Notebook", "Lab. Info. 2", "ana.r@gestao.local", StatusAtivo.DISPONIVEL, 90),
    ("PT-000410", "Desktop HP ProDesk 400 G7", "Desktop", "Lab. Info. 1", None, StatusAtivo.EM_USO, 20),
    ("PT-000411", "Desktop HP ProDesk 400 G7", "Desktop", "Lab. Info. 1", None, StatusAtivo.EM_USO, -5),
    ("PT-000412", "Desktop HP ProDesk 400 G7", "Desktop", "Lab. Info. 2", None, StatusAtivo.DISPONIVEL, 45),
    ("PT-000520", "Monitor LG 24\" Full HD", "Monitor", "Lab. Info. 2", None, StatusAtivo.DISPONIVEL, None),
    ("PT-000521", "Monitor LG 24\" Full HD", "Monitor", "Almoxarifado", None, StatusAtivo.DISPONIVEL, None),
    ("PT-000600", "Projetor Epson PowerLite X49", "Projetor", "Lab. Info. 1", "carlos.m@gestao.local", StatusAtivo.EM_USO, 10),
    ("PT-000710", "Impressora 3D Creality Ender 3 V2", "Impressora 3D", "Lab. Maker", "ana.r@gestao.local", StatusAtivo.EM_USO, 15),
    ("PT-000711", "Impressora 3D Bambu Lab P1S", "Impressora 3D", "Lab. Maker", "ana.r@gestao.local", StatusAtivo.DISPONIVEL, 30),
    ("PT-000800", "Osciloscópio Rigol DS1054Z", "Bancada eletrônica", "Lab. Eletrônica", None, StatusAtivo.DISPONIVEL, 120),
    ("PT-000801", "Fonte de bancada Minipa MPL-3305M", "Bancada eletrônica", "Lab. Eletrônica", None, StatusAtivo.DISPONIVEL, None),
    ("PT-000900", "Switch Cisco SG350-28", "Rede", "Sala de Manutenção", None, StatusAtivo.EM_USO, 180),
    ("PT-000150", "Notebook Positivo Master N250i", "Notebook", "Almoxarifado", None, StatusAtivo.INATIVO, None),
]


class Command(BaseCommand):
    help = "Popula o banco com dados fictícios para demonstração."

    def add_arguments(self, parser):
        parser.add_argument("--limpar", action="store_true", help="Apaga dados de ativos antes de popular.")

    @transaction.atomic
    def handle(self, *args, **opcoes):
        if opcoes["limpar"]:
            LogAuditoria.objects.all().delete()
            Movimentacao.objects.all().delete()
            Manutencao.objects.all().delete()
            Ativo.todos.all().delete()

        usuarios = {}
        for nome, email, senha, cargo in USUARIOS:
            usuario = Usuario.objects.todos().filter(email=email).first()
            if usuario is None:
                usuario = Usuario.objects.create_user(email, senha, nome=nome, cargo=cargo)
            usuarios[email] = usuario

        categorias = {n: Categoria.objects.get_or_create(nome=n)[0] for n in CATEGORIAS}
        locais = {n: Localizacao.objects.get_or_create(nome=n, defaults={"descricao": d})[0] for n, d in LOCAIS}

        hoje = timezone.localdate()
        criados = 0
        for ident, nome, cat, local, resp, status, dias in ATIVOS:
            _, novo = Ativo.todos.get_or_create(
                identificacao=ident,
                defaults={
                    "nome": nome,
                    "descricao": f"{nome} — patrimônio {ident}",
                    "categoria": categorias[cat],
                    "localizacao": locais[local],
                    "responsavel": usuarios.get(resp) if resp else None,
                    "status": status,
                    "proxima_manutencao": hoje + timedelta(days=dias) if dias is not None else None,
                },
            )
            criados += novo

        if not Movimentacao.objects.exists():
            self._historico(usuarios, locais, hoje)

        self.stdout.write(self.style.SUCCESS(f"Dados de demonstração prontos ({criados} ativos novos)."))
        self.stdout.write("Logins de demonstração (dados fictícios):")
        for _, email, senha, cargo in USUARIOS:
            self.stdout.write(f"  {cargo:<5}  {email:<24} {senha}")

    def _historico(self, usuarios, locais, hoje):
        carlos = usuarios["carlos.m@gestao.local"]
        admin = usuarios["admin@gestao.local"]
        agora = timezone.now()

        # PT-000324 veio do almoxarifado para o Lab. Info. 1
        nb = Ativo.objects.get(identificacao="PT-000324")
        Movimentacao.objects.create(
            ativo=nb, origem=locais["Almoxarifado"], destino=locais["Lab. Info. 2"],
            observacao="Entrega inicial ao laboratório.", registrado_por=admin,
            realizada_em=agora - timedelta(days=40),
        )
        Movimentacao.objects.create(
            ativo=nb, origem=locais["Lab. Info. 2"], destino=locais["Lab. Info. 1"],
            observacao="Remanejado para aula de redes.", registrado_por=carlos,
            realizada_em=agora - timedelta(days=12),
        )
        Manutencao.objects.create(
            ativo=nb, tipo=TipoManutencao.PREVENTIVA, status=StatusOS.CONCLUIDA,
            descricao="Limpeza interna e troca de pasta térmica.",
            aberta_em=agora - timedelta(days=30), realizada_em=hoje - timedelta(days=28),
            proxima_prevista=hoje + timedelta(days=60), custo=Decimal("80.00"), registrado_por=carlos,
        )

        # PT-000411 com OS corretiva em andamento
        pc = Ativo.objects.get(identificacao="PT-000411")
        Manutencao.objects.create(
            ativo=pc, tipo=TipoManutencao.CORRETIVA, status=StatusOS.EM_ANDAMENTO,
            descricao="Computador não liga — verificar fonte.", aberta_em=agora - timedelta(days=2),
            registrado_por=carlos,
        )
        pc.status = StatusAtivo.EM_MANUTENCAO
        pc.save(update_fields=["status"])

        # PT-000710 com OS aberta
        imp = Ativo.objects.get(identificacao="PT-000710")
        Manutencao.objects.create(
            ativo=imp, tipo=TipoManutencao.CORRETIVA, status=StatusOS.ABERTA,
            descricao="Bico entupido, falha na extrusão.", aberta_em=agora - timedelta(hours=5),
            registrado_por=usuarios["ana.r@gestao.local"],
        )
        imp.status = StatusAtivo.EM_MANUTENCAO
        imp.save(update_fields=["status"])

        mon = Ativo.objects.get(identificacao="PT-000520")
        Movimentacao.objects.create(
            ativo=mon, origem=locais["Almoxarifado"], destino=locais["Lab. Info. 2"],
            observacao="Monitor adicional para bancada do professor.", registrado_por=carlos,
            realizada_em=agora - timedelta(days=3),
        )
