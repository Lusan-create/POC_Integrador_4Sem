"""Padroniza as respostas de erro da API em português e registra acessos negados."""
from django.core.exceptions import ValidationError as DjangoValidationError
from django.db.models import ProtectedError, RestrictedError
from rest_framework import status
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response
from rest_framework.views import exception_handler


def tratar_excecao(exc, context):
    # Violação de ON DELETE RESTRICT: o registro ainda está em uso.
    if isinstance(exc, (ProtectedError, RestrictedError)):
        return Response(
            {"detail": "Não é possível excluir: o registro está vinculado a outros dados."},
            status=status.HTTP_409_CONFLICT,
        )
    # Regras de negócio validadas no model (clean / CheckConstraint).
    if isinstance(exc, DjangoValidationError):
        dados = exc.message_dict if hasattr(exc, "error_dict") else {"detail": exc.messages}
        return Response(dados, status=status.HTTP_400_BAD_REQUEST)

    # Usuário autenticado tentando uma ação fora do seu perfil (RS02 / H03).
    request = context.get("request")
    if isinstance(exc, PermissionDenied) and request is not None and request.user.is_authenticated:
        from auditoria.models import Acao
        from auditoria.servicos import registrar

        registrar(
            Acao.ACESSO_NEGADO,
            request=request,
            entidade=getattr(context.get("view"), "basename", "") or "",
            entidade_id=(context.get("kwargs") or {}).get("pk", ""),
            descricao=f"Acesso negado: {request.method} {request.path}",
        )
    return exception_handler(exc, context)
