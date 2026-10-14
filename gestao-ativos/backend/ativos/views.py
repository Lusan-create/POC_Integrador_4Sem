import io
from datetime import timedelta

import qrcode
from django.db.models import Count, Q
from django.http import HttpResponse
from django.shortcuts import get_object_or_404
from django.utils import timezone
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import mixins, status, viewsets
from rest_framework.decorators import action, api_view
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.response import Response

from auditoria.models import Acao
from auditoria.servicos import registrar
from contas.permissoes import AdminOuSomenteLeitura, EhAdmin

from . import servicos
from .models import (
    STATUS_OS_PENDENTES, Ativo, Categoria, Localizacao, Manutencao, Movimentacao, StatusAtivo,
)
from .serializers import (
    AtivoSerializer, CategoriaSerializer, LocalizacaoSerializer, ManutencaoSerializer,
    MovimentacaoSerializer,
)


class RegistroAuditadoMixin:
    """Grava no log de auditoria as criações, edições e exclusões feitas pelo ViewSet."""

    entidade = ""

    def _descrever(self, obj):
        return str(obj)

    def perform_create(self, serializer):
        obj = serializer.save()
        registrar(Acao.CRIAR, request=self.request, entidade=self.entidade, entidade_id=obj.pk,
                  descricao=f"{self.entidade.capitalize()} criado(a): {self._descrever(obj)}")

    def perform_update(self, serializer):
        campos = sorted(serializer.validated_data.keys())
        obj = serializer.save()
        registrar(Acao.EDITAR, request=self.request, entidade=self.entidade, entidade_id=obj.pk,
                  descricao=f"{self.entidade.capitalize()} alterado(a): {self._descrever(obj)}",
                  detalhes={"campos": campos})

    def perform_destroy(self, obj):
        pk, texto = obj.pk, self._descrever(obj)
        obj.delete()
        registrar(Acao.EXCLUIR, request=self.request, entidade=self.entidade, entidade_id=pk,
                  descricao=f"{self.entidade.capitalize()} excluído(a): {texto}")


class CategoriaViewSet(RegistroAuditadoMixin, viewsets.ModelViewSet):
    queryset = Categoria.objects.all()
    serializer_class = CategoriaSerializer
    permission_classes = [AdminOuSomenteLeitura]
    pagination_class = None
    search_fields = ["nome"]
    entidade = "categoria"


class LocalizacaoViewSet(RegistroAuditadoMixin, viewsets.ModelViewSet):
    queryset = Localizacao.objects.all()
    serializer_class = LocalizacaoSerializer
    permission_classes = [AdminOuSomenteLeitura]
    pagination_class = None
    search_fields = ["nome", "descricao"]
    entidade = "localizacao"


class AtivoViewSet(RegistroAuditadoMixin, viewsets.ModelViewSet):
    """RF02, RF04, RF05, RF06 — cadastro, consulta, edição e inativação de ativos."""

    serializer_class = AtivoSerializer
    permission_classes = [AdminOuSomenteLeitura]
    filterset_fields = ["status", "categoria", "localizacao", "responsavel"]
    search_fields = ["identificacao", "nome", "descricao"]
    ordering_fields = ["identificacao", "nome", "status", "proxima_manutencao", "atualizado_em"]
    entidade = "ativo"

    def get_queryset(self):
        return Ativo.objects.select_related("categoria", "localizacao", "responsavel")

    def _descrever(self, obj):
        return obj.identificacao

    def perform_destroy(self, ativo):
        # Exclusão lógica (deletado_em) — o histórico continua preservado.
        ativo.deletado_em = timezone.now()
        ativo.save(update_fields=["deletado_em", "atualizado_em"])
        registrar(Acao.EXCLUIR, request=self.request, entidade="ativo", entidade_id=ativo.pk,
                  descricao=f"Ativo excluído: {ativo.identificacao}")

    @extend_schema(
        summary="Consultar ativo pelo código lido (QR Code / código de barras) ou digitado",
        parameters=[OpenApiParameter("codigo", OpenApiTypes.STR, OpenApiParameter.PATH)],
        responses=AtivoSerializer,
    )
    @action(detail=False, methods=["get"], url_path=r"codigo/(?P<codigo>[^/]+)")
    def por_codigo(self, request, codigo=None):
        """RF03 / RNF04 — mesma rota atende a leitura da câmera e a digitação manual."""
        ativo = get_object_or_404(self.get_queryset(), identificacao=codigo.strip().upper())
        return Response(self.get_serializer(ativo).data)

    @extend_schema(request=None, responses=AtivoSerializer)
    @action(detail=True, methods=["post"])
    def inativar(self, request, pk=None):
        ativo = self.get_object()
        if ativo.inativo:
            raise ValidationError({"detail": "O ativo já está inativo."})
        canceladas = ativo.manutencoes.filter(status__in=STATUS_OS_PENDENTES).count()
        servicos.inativar(ativo)
        registrar(Acao.INATIVAR, request=request, entidade="ativo", entidade_id=ativo.pk,
                  descricao=f"Ativo inativado: {ativo.identificacao}",
                  detalhes={"os_canceladas": canceladas})
        return Response(self.get_serializer(ativo).data)

    @extend_schema(request=None, responses=AtivoSerializer)
    @action(detail=True, methods=["post"])
    def reativar(self, request, pk=None):
        ativo = self.get_object()
        if not ativo.inativo:
            raise ValidationError({"detail": "O ativo não está inativo."})
        servicos.reativar(ativo)
        registrar(Acao.REATIVAR, request=request, entidade="ativo", entidade_id=ativo.pk,
                  descricao=f"Ativo reativado: {ativo.identificacao}")
        return Response(self.get_serializer(ativo).data)

    @extend_schema(summary="Histórico de movimentações e ordens de serviço (RF09)")
    @action(detail=True, methods=["get"])
    def historico(self, request, pk=None):
        ativo = self.get_object()
        movs = Movimentacao.objects.filter(ativo=ativo).select_related(
            "ativo", "origem", "destino", "registrado_por"
        )
        oss = Manutencao.objects.filter(ativo=ativo).select_related("ativo", "registrado_por")
        eventos = [
            {"tipo": "movimentacao", "data": m["realizada_em"], "registro": m}
            for m in MovimentacaoSerializer(movs, many=True).data
        ] + [
            {"tipo": "manutencao", "data": o["aberta_em"], "registro": o}
            for o in ManutencaoSerializer(oss, many=True).data
        ]
        eventos.sort(key=lambda e: e["data"], reverse=True)
        return Response({"ativo": self.get_serializer(ativo).data, "eventos": eventos})

    @extend_schema(summary="Etiqueta QR Code do ativo (PNG)", responses={(200, "image/png"): OpenApiTypes.BINARY})
    @action(detail=True, methods=["get"])
    def qrcode(self, request, pk=None):
        ativo = self.get_object()
        imagem = qrcode.make(ativo.identificacao, box_size=10, border=2)
        buffer = io.BytesIO()
        imagem.save(buffer, format="PNG")
        resposta = HttpResponse(buffer.getvalue(), content_type="image/png")
        resposta["Content-Disposition"] = f'inline; filename="qrcode-{ativo.identificacao}.png"'
        return resposta


class MovimentacaoViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin,
                          mixins.CreateModelMixin, viewsets.GenericViewSet):
    """RF07 — qualquer usuário autenticado registra movimentação. Registros não são editáveis."""

    serializer_class = MovimentacaoSerializer
    filterset_fields = ["ativo", "origem", "destino", "registrado_por"]
    ordering_fields = ["realizada_em"]

    def get_queryset(self):
        return Movimentacao.objects.select_related("ativo", "origem", "destino", "registrado_por")

    def perform_create(self, serializer):
        mov = servicos.registrar_movimentacao(serializer, self.request.user)
        registrar(Acao.MOVIMENTAR, request=self.request, entidade="ativo", entidade_id=mov.ativo_id,
                  descricao=f"{mov.ativo.identificacao}: {mov.origem.nome} → {mov.destino.nome}",
                  detalhes={"movimentacao_id": mov.pk})


class ManutencaoViewSet(viewsets.ModelViewSet):
    """RF08 — abertura e acompanhamento de ordens de serviço. Exclusão só para admin."""

    serializer_class = ManutencaoSerializer
    filterset_fields = {"ativo": ["exact"], "status": ["exact", "in"], "tipo": ["exact"]}
    search_fields = ["descricao", "ativo__identificacao", "ativo__nome"]
    ordering_fields = ["aberta_em", "realizada_em", "status"]
    http_method_names = ["get", "post", "patch", "delete", "head", "options"]

    def get_queryset(self):
        return Manutencao.objects.select_related("ativo", "registrado_por")

    def get_permissions(self):
        if self.action == "destroy":
            return [EhAdmin()]
        return super().get_permissions()

    def perform_create(self, serializer):
        os_ = servicos.salvar_manutencao(serializer, self.request.user)
        registrar(Acao.ABRIR_OS, request=self.request, entidade="manutencao", entidade_id=os_.pk,
                  descricao=f"OS #{os_.pk} aberta para {os_.ativo.identificacao}",
                  detalhes={"tipo": os_.tipo, "status": os_.status})

    def perform_update(self, serializer):
        anterior = serializer.instance.status
        os_ = servicos.salvar_manutencao(serializer)
        registrar(Acao.ATUALIZAR_OS, request=self.request, entidade="manutencao", entidade_id=os_.pk,
                  descricao=f"OS #{os_.pk} ({os_.ativo.identificacao}) atualizada",
                  detalhes={"status_anterior": anterior, "status": os_.status,
                            "campos": sorted(serializer.validated_data.keys())})

    def perform_destroy(self, os_):
        pk, ativo = os_.pk, os_.ativo
        os_.delete()
        servicos._atualizar_status_do_ativo(ativo)
        registrar(Acao.EXCLUIR, request=self.request, entidade="manutencao", entidade_id=pk,
                  descricao=f"OS #{pk} ({ativo.identificacao}) excluída")


@extend_schema(summary="Indicadores para o painel web", responses=OpenApiTypes.OBJECT)
@api_view(["GET"])
def painel(request):
    hoje = timezone.localdate()
    por_status = dict(Ativo.objects.values_list("status").order_by().annotate(total=Count("id")))
    proximas = (
        Ativo.objects.exclude(status=StatusAtivo.INATIVO)
        .filter(proxima_manutencao__isnull=False, proxima_manutencao__lte=hoje + timedelta(days=30))
        .select_related("localizacao")
        .order_by("proxima_manutencao")[:10]
    )
    return Response({
        "total_ativos": sum(por_status.values()),
        "por_status": {s.value: por_status.get(s.value, 0) for s in StatusAtivo},
        "os_pendentes": Manutencao.objects.filter(status__in=STATUS_OS_PENDENTES).count(),
        "movimentacoes_30_dias": Movimentacao.objects.filter(
            realizada_em__gte=timezone.now() - timedelta(days=30)
        ).count(),
        "manutencoes_proximas": [
            {
                "id": a.id, "identificacao": a.identificacao, "nome": a.nome,
                "localizacao": a.localizacao.nome, "proxima_manutencao": a.proxima_manutencao,
                "atrasada": a.proxima_manutencao < hoje,
            }
            for a in proximas
        ],
        "por_localizacao": list(
            Localizacao.objects.annotate(
                total=Count("ativos", filter=Q(ativos__deletado_em__isnull=True))
            ).values("id", "nome", "total")
        ),
    })
