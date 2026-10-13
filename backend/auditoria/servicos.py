"""Função única para gravar logs de auditoria a partir de qualquer parte do sistema."""
from .models import LogAuditoria

# Chaves que jamais devem chegar ao log (RS04).
CHAVES_SENSIVEIS = {"password", "senha", "senha_hash", "token", "access", "refresh", "authorization"}


def _limpar(valor):
    if isinstance(valor, dict):
        return {
            k: ("***" if k.lower() in CHAVES_SENSIVEIS else _limpar(v)) for k, v in valor.items()
        }
    if isinstance(valor, (list, tuple)):
        return [_limpar(v) for v in valor]
    if isinstance(valor, (str, int, float, bool)) or valor is None:
        return valor
    return str(valor)


def ip_da_requisicao(request):
    if request is None:
        return None
    # REMOTE_ADDR é definido pelo servidor; X-Forwarded-For pode ser forjado pelo cliente.
    return request.META.get("REMOTE_ADDR") or None


def registrar(acao, *, request=None, usuario=None, entidade="", entidade_id="", descricao="", detalhes=None, email=""):
    if usuario is None and request is not None and getattr(request, "user", None) is not None:
        if request.user.is_authenticated:
            usuario = request.user
    return LogAuditoria.objects.create(
        usuario=usuario,
        usuario_email=(usuario.email if usuario else email)[:255],
        acao=acao,
        entidade=entidade,
        entidade_id=str(entidade_id or ""),
        descricao=descricao[:500],
        detalhes=_limpar(detalhes or {}),
        ip=ip_da_requisicao(request),
    )
