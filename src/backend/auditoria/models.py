from django.conf import settings
from django.db import models
from django.db.models.functions import Now
from django.utils import timezone


class Acao(models.TextChoices):
    LOGIN = "login", "Login"
    LOGIN_FALHA = "login_falha", "Falha de login"
    ACESSO_NEGADO = "acesso_negado", "Acesso negado"
    CRIAR = "criar", "Criação"
    EDITAR = "editar", "Edição"
    EXCLUIR = "excluir", "Exclusão"
    INATIVAR = "inativar", "Inativação"
    REATIVAR = "reativar", "Reativação"
    MOVIMENTAR = "movimentar", "Movimentação"
    ABRIR_OS = "abrir_os", "Abertura de OS"
    ATUALIZAR_OS = "atualizar_os", "Atualização de OS"


class LogAuditoria(models.Model):
    """Registro das principais ações (RS04). Nunca armazena senha ou token."""

    usuario = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="logs"
    )
    # Cópia do e-mail no momento da ação: mantém o rastro mesmo se o usuário for excluído,
    # e permite registrar tentativas de login com e-mail inexistente.
    usuario_email = models.CharField(max_length=255, blank=True, default="")
    acao = models.CharField(max_length=20, choices=Acao.choices)
    entidade = models.CharField(max_length=40, blank=True, default="")
    entidade_id = models.CharField(max_length=40, blank=True, default="")
    descricao = models.CharField(max_length=500, blank=True, default="")
    detalhes = models.JSONField(default=dict, blank=True)
    ip = models.GenericIPAddressField(null=True, blank=True)
    criado_em = models.DateTimeField(default=timezone.now, db_default=Now(), db_index=True)

    class Meta:
        db_table = "log_auditoria"
        ordering = ["-criado_em", "-id"]
        verbose_name = "log de auditoria"
        verbose_name_plural = "logs de auditoria"

    def __str__(self):
        return f"[{self.criado_em:%d/%m/%Y %H:%M}] {self.usuario_email} — {self.get_acao_display()}"
