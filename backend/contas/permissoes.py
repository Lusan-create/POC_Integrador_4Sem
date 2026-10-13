"""Controle de acesso por perfil (RS02)."""
from rest_framework.permissions import SAFE_METHODS, BasePermission


class EhAdmin(BasePermission):
    message = "Ação permitida somente para administradores."

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.is_admin)


class AdminOuSomenteLeitura(BasePermission):
    """Qualquer usuário autenticado consulta; somente o admin cria, edita ou exclui."""

    message = "Ação permitida somente para administradores."

    def has_permission(self, request, view):
        if not (request.user and request.user.is_authenticated):
            return False
        return request.method in SAFE_METHODS or request.user.is_admin
