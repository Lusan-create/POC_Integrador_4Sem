from django.utils import timezone
from drf_spectacular.utils import extend_schema
from rest_framework import status, viewsets
from rest_framework.decorators import api_view, permission_classes
from rest_framework.exceptions import AuthenticationFailed, ValidationError
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework_simplejwt.views import TokenObtainPairView

from auditoria.models import Acao
from auditoria.servicos import registrar

from .models import Usuario
from .serializers import LoginSerializer, PerfilSerializer, UsuarioSerializer


class LoginView(TokenObtainPairView):
    """RF01 — autentica pelo e-mail e senha e devolve os tokens JWT."""

    serializer_class = LoginSerializer
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "login"

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        email = str(request.data.get("email", "")).strip().lower()[:255]
        try:
            serializer.is_valid(raise_exception=True)
        except (AuthenticationFailed, ValidationError):
            registrar(Acao.LOGIN_FALHA, request=request, email=email, entidade="usuario",
                      descricao="Tentativa de login recusada.")
            raise
        registrar(Acao.LOGIN, request=request, usuario=serializer.user, entidade="usuario",
                  entidade_id=serializer.user.pk, descricao="Login realizado.")
        return Response(serializer.validated_data, status=status.HTTP_200_OK)


@extend_schema(responses=PerfilSerializer)
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def eu(request):
    """Dados do usuário autenticado."""
    return Response(PerfilSerializer(request.user).data)


class UsuarioViewSet(viewsets.ModelViewSet):
    """Gestão de usuários."""

    serializer_class = UsuarioSerializer
    queryset = Usuario.objects.all()
    search_fields = ["nome", "email"]
    filterset_fields = ["cargo"]
    ordering_fields = ["nome", "email", "criado_em"]

    def perform_create(self, serializer):
        usuario = serializer.save()
        registrar(Acao.CRIAR, request=self.request, entidade="usuario", entidade_id=usuario.pk,
                  descricao=f"Usuário {usuario.email} criado.", detalhes={"cargo": usuario.cargo})

    def perform_update(self, serializer):
        alterados = sorted(k for k in serializer.validated_data if k != "senha")
        if "senha" in serializer.validated_data:
            alterados.append("senha (alterada)")
        usuario = serializer.save()
        registrar(Acao.EDITAR, request=self.request, entidade="usuario", entidade_id=usuario.pk,
                  descricao=f"Usuário {usuario.email} alterado.", detalhes={"campos": alterados})

    def perform_destroy(self, usuario):
        if self.request.user.is_authenticated and usuario.pk == self.request.user.pk:
            raise ValidationError({"detail": "Você não pode excluir o próprio usuário."})
        # Exclusão lógica: preserva o histórico de ações do usuário.
        usuario.deletado_em = timezone.now()
        usuario.save(update_fields=["deletado_em", "atualizado_em"])
        registrar(Acao.EXCLUIR, request=self.request, entidade="usuario", entidade_id=usuario.pk,
                  descricao=f"Usuário {usuario.email} excluído.")
