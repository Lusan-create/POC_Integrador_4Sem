"""
Modelos do domínio de ativos — seguem o DER "3.2 Modelo de dados", com as
extensões aprovadas pelo grupo:

* ATIVO ganhou `nome` e `status` (situação exibida na consulta e usada na inativação — RF06);
* MANUTENCAO passou a representar também a Ordem de Serviço (`tipo`, `status`, `aberta_em`);
  `realizada_em` ficou opcional porque só é preenchida quando a OS é concluída;
* nova tabela MOVIMENTACAO (RF07/RF09).
"""
from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models
from django.db.models import F, Q
from django.db.models.functions import Now
from django.utils import timezone


class Categoria(models.Model):
    nome = models.CharField(max_length=80, unique=True)
    criado_em = models.DateTimeField(default=timezone.now, db_default=Now())

    class Meta:
        db_table = "categoria"
        ordering = ["nome"]

    def __str__(self):
        return self.nome


class Localizacao(models.Model):
    nome = models.CharField(max_length=80, unique=True)
    descricao = models.CharField(max_length=255, null=True, blank=True)
    criado_em = models.DateTimeField(default=timezone.now, db_default=Now())

    class Meta:
        db_table = "localizacao"
        ordering = ["nome"]
        verbose_name = "localização"
        verbose_name_plural = "localizações"

    def __str__(self):
        return self.nome


class StatusAtivo(models.TextChoices):
    DISPONIVEL = "disponivel", "Disponível"
    EM_USO = "em_uso", "Em uso"
    EM_MANUTENCAO = "em_manutencao", "Em manutenção"
    INATIVO = "inativo", "Inativo"


class AtivoManager(models.Manager):
    """Equivalente à VIEW vw_ativo: apenas ativos não excluídos."""

    def get_queryset(self):
        return super().get_queryset().filter(deletado_em__isnull=True)


class Ativo(models.Model):
    # Número de patrimônio — é o conteúdo gravado no QR Code / código de barras.
    identificacao = models.CharField("patrimônio", max_length=30, unique=True)
    nome = models.CharField(max_length=120)
    descricao = models.CharField(max_length=255, blank=True, default="")
    categoria = models.ForeignKey(Categoria, on_delete=models.RESTRICT, related_name="ativos")
    localizacao = models.ForeignKey(Localizacao, on_delete=models.RESTRICT, related_name="ativos")
    responsavel = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="ativos_sob_responsabilidade",
    )
    status = models.CharField(max_length=20, choices=StatusAtivo.choices, default=StatusAtivo.DISPONIVEL)
    ultima_manutencao = models.DateField(null=True, blank=True)
    proxima_manutencao = models.DateField(null=True, blank=True, db_index=True)
    criado_em = models.DateTimeField(default=timezone.now, db_default=Now())
    atualizado_em = models.DateTimeField(auto_now=True, db_default=Now())
    deletado_em = models.DateTimeField(null=True, blank=True)

    objects = AtivoManager()
    todos = models.Manager()

    class Meta:
        db_table = "ativo"
        ordering = ["identificacao"]
        base_manager_name = "todos"
        constraints = [
            models.CheckConstraint(
                condition=Q(ultima_manutencao__isnull=True)
                | Q(proxima_manutencao__isnull=True)
                | Q(proxima_manutencao__gte=F("ultima_manutencao")),
                name="ck_ativo_proxima_manutencao",
            ),
            models.CheckConstraint(
                condition=Q(status__in=[s.value for s in StatusAtivo]),
                name="ck_ativo_status",
            ),
        ]

    def __str__(self):
        return f"{self.identificacao} — {self.nome}"

    def save(self, *args, **kwargs):
        self.identificacao = (self.identificacao or "").strip().upper()
        super().save(*args, **kwargs)

    @property
    def inativo(self):
        return self.status == StatusAtivo.INATIVO


class Movimentacao(models.Model):
    ativo = models.ForeignKey(Ativo, on_delete=models.RESTRICT, related_name="movimentacoes")
    origem = models.ForeignKey(
        Localizacao, on_delete=models.RESTRICT, related_name="movimentacoes_saida"
    )
    destino = models.ForeignKey(
        Localizacao, on_delete=models.RESTRICT, related_name="movimentacoes_entrada"
    )
    observacao = models.CharField(max_length=500, blank=True, default="")
    registrado_por = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="movimentacoes_registradas",
    )
    realizada_em = models.DateTimeField(default=timezone.now, db_default=Now())

    class Meta:
        db_table = "movimentacao"
        ordering = ["-realizada_em", "-id"]
        verbose_name = "movimentação"
        verbose_name_plural = "movimentações"
        constraints = [
            models.CheckConstraint(
                condition=~Q(origem=F("destino")),
                name="ck_movimentacao_origem_destino",
            ),
        ]

    def __str__(self):
        return f"{self.ativo.identificacao}: {self.origem} → {self.destino}"


class TipoManutencao(models.TextChoices):
    CORRETIVA = "corretiva", "Corretiva"
    PREVENTIVA = "preventiva", "Preventiva"


class StatusOS(models.TextChoices):
    ABERTA = "aberta", "Aberta"
    EM_ANDAMENTO = "em_andamento", "Em andamento"
    CONCLUIDA = "concluida", "Concluída"
    CANCELADA = "cancelada", "Cancelada"


STATUS_OS_PENDENTES = (StatusOS.ABERTA, StatusOS.EM_ANDAMENTO)


class Manutencao(models.Model):
    """Manutenção / Ordem de Serviço vinculada a um ativo (RF08)."""

    ativo = models.ForeignKey(Ativo, on_delete=models.RESTRICT, related_name="manutencoes")
    tipo = models.CharField(max_length=20, choices=TipoManutencao.choices, default=TipoManutencao.CORRETIVA)
    status = models.CharField(max_length=20, choices=StatusOS.choices, default=StatusOS.ABERTA)
    descricao = models.CharField(max_length=500, null=True, blank=True)
    aberta_em = models.DateTimeField(default=timezone.now, db_default=Now())
    realizada_em = models.DateField(null=True, blank=True)
    proxima_prevista = models.DateField(null=True, blank=True)
    custo = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    registrado_por = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="manutencoes_registradas",
    )
    criado_em = models.DateTimeField(default=timezone.now, db_default=Now())

    class Meta:
        db_table = "manutencao"
        ordering = ["-aberta_em", "-id"]
        verbose_name = "manutenção / OS"
        verbose_name_plural = "manutenções / OS"
        constraints = [
            models.CheckConstraint(
                condition=Q(realizada_em__isnull=True)
                | Q(proxima_prevista__isnull=True)
                | Q(proxima_prevista__gte=F("realizada_em")),
                name="ck_manutencao_proxima_prevista",
            ),
            models.CheckConstraint(
                condition=Q(custo__isnull=True) | Q(custo__gte=0),
                name="ck_manutencao_custo",
            ),
            models.CheckConstraint(
                condition=Q(tipo__in=[t.value for t in TipoManutencao]),
                name="ck_manutencao_tipo",
            ),
            models.CheckConstraint(
                condition=Q(status__in=[s.value for s in StatusOS]),
                name="ck_manutencao_status",
            ),
            # OS concluída precisa ter a data de realização.
            models.CheckConstraint(
                condition=~Q(status="concluida") | Q(realizada_em__isnull=False),
                name="ck_manutencao_concluida_com_data",
            ),
        ]

    def __str__(self):
        return f"OS #{self.pk} — {self.ativo.identificacao} ({self.get_status_display()})"

    def clean(self):
        if self.status == StatusOS.CONCLUIDA and not self.realizada_em:
            raise ValidationError({"realizada_em": "Informe a data de realização para concluir a OS."})
        if self.realizada_em and self.proxima_prevista and self.proxima_prevista < self.realizada_em:
            raise ValidationError({"proxima_prevista": "A próxima manutenção deve ser posterior à realização."})
