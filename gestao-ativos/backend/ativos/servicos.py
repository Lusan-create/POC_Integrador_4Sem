"""Regras de negócio que alteram mais de uma tabela — sempre em transação."""
from django.db import transaction

from .models import STATUS_OS_PENDENTES, Ativo, Manutencao, StatusAtivo, StatusOS


@transaction.atomic
def registrar_movimentacao(serializer, usuario):
    ativo = Ativo.objects.select_for_update().get(pk=serializer.validated_data["ativo"].pk)
    movimentacao = serializer.save(origem=ativo.localizacao, registrado_por=usuario)
    ativo.localizacao = movimentacao.destino
    ativo.save(update_fields=["localizacao", "atualizado_em"])
    return movimentacao


def _atualizar_status_do_ativo(ativo):
    """Ativo fica 'em manutenção' enquanto houver OS pendente; ao encerrar, volta a 'disponível'."""
    if ativo.inativo:
        return
    pendente = Manutencao.objects.filter(ativo=ativo, status__in=STATUS_OS_PENDENTES).exists()
    if pendente and ativo.status != StatusAtivo.EM_MANUTENCAO:
        ativo.status = StatusAtivo.EM_MANUTENCAO
        ativo.save(update_fields=["status", "atualizado_em"])
    elif not pendente and ativo.status == StatusAtivo.EM_MANUTENCAO:
        ativo.status = StatusAtivo.DISPONIVEL
        ativo.save(update_fields=["status", "atualizado_em"])


@transaction.atomic
def salvar_manutencao(serializer, usuario=None):
    extra = {"registrado_por": usuario} if usuario is not None else {}
    manutencao = serializer.save(**extra)
    # As datas de última/próxima manutenção do ativo são atualizadas pelo trigger do banco
    # (trg_manutencao_atualiza_ativo); aqui recarregamos o ativo e ajustamos o status.
    ativo = Ativo.todos.select_for_update().get(pk=manutencao.ativo_id)
    _atualizar_status_do_ativo(ativo)
    return manutencao


@transaction.atomic
def inativar(ativo):
    pendentes = ativo.manutencoes.filter(status__in=STATUS_OS_PENDENTES)
    pendentes.update(status=StatusOS.CANCELADA)
    ativo.status = StatusAtivo.INATIVO
    ativo.save(update_fields=["status", "atualizado_em"])


def reativar(ativo):
    ativo.status = StatusAtivo.DISPONIVEL
    ativo.save(update_fields=["status", "atualizado_em"])
