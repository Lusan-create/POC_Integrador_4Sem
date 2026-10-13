from rest_framework import serializers, viewsets

from contas.permissoes import EhAdmin

from .models import LogAuditoria


class LogAuditoriaSerializer(serializers.ModelSerializer):
    acao_exibicao = serializers.CharField(source="get_acao_display", read_only=True)

    class Meta:
        model = LogAuditoria
        fields = [
            "id", "usuario", "usuario_email", "acao", "acao_exibicao", "entidade", "entidade_id",
            "descricao", "detalhes", "ip", "criado_em",
        ]


class LogAuditoriaViewSet(viewsets.ReadOnlyModelViewSet):
    """Consulta dos logs (RS04) — somente administradores; logs não podem ser alterados."""

    queryset = LogAuditoria.objects.all()
    serializer_class = LogAuditoriaSerializer
    permission_classes = [EhAdmin]
    filterset_fields = ["acao", "entidade", "entidade_id", "usuario"]
    search_fields = ["usuario_email", "descricao"]
    ordering_fields = ["criado_em"]
