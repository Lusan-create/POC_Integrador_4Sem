import re

from drf_spectacular.utils import extend_schema_field
from rest_framework import serializers

from contas.models import Usuario
from contas.serializers import UsuarioResumoSerializer

from .models import (
    Ativo, Categoria, Localizacao, Manutencao, Movimentacao, StatusAtivo, StatusOS,
)

PADRAO_IDENTIFICACAO = re.compile(r"^[A-Z0-9][A-Z0-9\-_.]{1,29}$")


class AtivoResumoSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    identificacao = serializers.CharField()
    nome = serializers.CharField()


class CategoriaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Categoria
        fields = ["id", "nome", "criado_em"]
        read_only_fields = ["criado_em"]

    def validate_nome(self, valor):
        valor = valor.strip()
        if not valor:
            raise serializers.ValidationError("Informe o nome.")
        return valor


class LocalizacaoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Localizacao
        fields = ["id", "nome", "descricao", "criado_em"]
        read_only_fields = ["criado_em"]

    def validate_nome(self, valor):
        valor = valor.strip()
        if not valor:
            raise serializers.ValidationError("Informe o nome.")
        return valor


class AtivoSerializer(serializers.ModelSerializer):
    """Leitura com os dados relacionados já resolvidos; escrita pelos IDs."""

    categoria = CategoriaSerializer(read_only=True)
    localizacao = LocalizacaoSerializer(read_only=True)
    responsavel = UsuarioResumoSerializer(read_only=True)
    status_exibicao = serializers.CharField(source="get_status_display", read_only=True)

    categoria_id = serializers.PrimaryKeyRelatedField(
        source="categoria", queryset=Categoria.objects.all(), write_only=True
    )
    localizacao_id = serializers.PrimaryKeyRelatedField(
        source="localizacao", queryset=Localizacao.objects.all(), write_only=True
    )
    responsavel_id = serializers.PrimaryKeyRelatedField(
        source="responsavel", queryset=Usuario.objects.all(), write_only=True,
        required=False, allow_null=True,
    )

    class Meta:
        model = Ativo
        fields = [
            "id", "identificacao", "nome", "descricao",
            "categoria", "localizacao", "responsavel",
            "categoria_id", "localizacao_id", "responsavel_id",
            "status", "status_exibicao", "ultima_manutencao", "proxima_manutencao",
            "criado_em", "atualizado_em",
        ]
        read_only_fields = ["criado_em", "atualizado_em", "ultima_manutencao"]

    def validate_identificacao(self, valor):
        valor = valor.strip().upper()
        if not PADRAO_IDENTIFICACAO.match(valor):
            raise serializers.ValidationError(
                "Use de 2 a 30 caracteres: letras, números, hífen, ponto ou sublinhado (ex.: PT-000324)."
            )
        existente = Ativo.todos.filter(identificacao=valor)
        if self.instance:
            existente = existente.exclude(pk=self.instance.pk)
        if existente.exists():
            raise serializers.ValidationError("Já existe um ativo com este patrimônio.")
        return valor

    def validate_nome(self, valor):
        valor = valor.strip()
        if len(valor) < 2:
            raise serializers.ValidationError("Informe o nome do ativo.")
        return valor

    def validate_status(self, valor):
        # Inativação e manutenção têm fluxos próprios (endpoints inativar / OS).
        atual = self.instance.status if self.instance else None
        if valor == StatusAtivo.INATIVO and atual != StatusAtivo.INATIVO:
            raise serializers.ValidationError("Use a ação 'inativar' para inativar o ativo.")
        if atual == StatusAtivo.INATIVO and valor != StatusAtivo.INATIVO:
            raise serializers.ValidationError("Use a ação 'reativar' para reativar o ativo.")
        return valor

    def validate(self, dados):
        ultima = self.instance.ultima_manutencao if self.instance else None
        proxima = dados.get("proxima_manutencao")
        if ultima and proxima and proxima < ultima:
            raise serializers.ValidationError(
                {"proxima_manutencao": "Deve ser igual ou posterior à última manutenção."}
            )
        return dados


class MovimentacaoSerializer(serializers.ModelSerializer):
    ativo = serializers.SerializerMethodField()
    origem = LocalizacaoSerializer(read_only=True)
    destino = LocalizacaoSerializer(read_only=True)
    registrado_por = UsuarioResumoSerializer(read_only=True)

    ativo_id = serializers.PrimaryKeyRelatedField(
        source="ativo", queryset=Ativo.objects.all(), write_only=True
    )
    destino_id = serializers.PrimaryKeyRelatedField(
        source="destino", queryset=Localizacao.objects.all(), write_only=True
    )

    class Meta:
        model = Movimentacao
        fields = [
            "id", "ativo", "ativo_id", "origem", "destino", "destino_id",
            "observacao", "registrado_por", "realizada_em",
        ]
        read_only_fields = ["realizada_em"]

    @extend_schema_field(AtivoResumoSerializer)
    def get_ativo(self, obj):
        return {"id": obj.ativo_id, "identificacao": obj.ativo.identificacao, "nome": obj.ativo.nome}

    def validate(self, dados):
        ativo, destino = dados["ativo"], dados["destino"]
        if ativo.inativo:
            raise serializers.ValidationError({"ativo_id": "Ativo inativo não pode ser movimentado."})
        if ativo.localizacao_id == destino.pk:
            raise serializers.ValidationError({"destino_id": "O ativo já está neste local."})
        dados["observacao"] = dados.get("observacao", "").strip()
        return dados


class ManutencaoSerializer(serializers.ModelSerializer):
    ativo = serializers.SerializerMethodField()
    registrado_por = UsuarioResumoSerializer(read_only=True)
    tipo_exibicao = serializers.CharField(source="get_tipo_display", read_only=True)
    status_exibicao = serializers.CharField(source="get_status_display", read_only=True)
    ativo_id = serializers.PrimaryKeyRelatedField(
        source="ativo", queryset=Ativo.objects.all(), write_only=True
    )

    class Meta:
        model = Manutencao
        fields = [
            "id", "ativo", "ativo_id", "tipo", "tipo_exibicao", "status", "status_exibicao",
            "descricao", "aberta_em", "realizada_em", "proxima_prevista", "custo",
            "registrado_por", "criado_em",
        ]
        read_only_fields = ["aberta_em", "criado_em"]
        extra_kwargs = {"custo": {"min_value": 0}}

    @extend_schema_field(AtivoResumoSerializer)
    def get_ativo(self, obj):
        return {"id": obj.ativo_id, "identificacao": obj.ativo.identificacao, "nome": obj.ativo.nome}

    def validate(self, dados):
        inst = self.instance
        ativo = dados.get("ativo", inst.ativo if inst else None)
        status = dados.get("status", inst.status if inst else StatusOS.ABERTA)
        realizada = dados.get("realizada_em", inst.realizada_em if inst else None)
        proxima = dados.get("proxima_prevista", inst.proxima_prevista if inst else None)

        if inst and "ativo" in dados and dados["ativo"].pk != inst.ativo_id:
            raise serializers.ValidationError({"ativo_id": "Não é possível trocar o ativo de uma OS."})
        if inst is None and ativo.inativo:
            raise serializers.ValidationError({"ativo_id": "Não é possível abrir OS para ativo inativo."})
        if inst and inst.status in (StatusOS.CONCLUIDA, StatusOS.CANCELADA):
            raise serializers.ValidationError({"status": "OS encerrada não pode ser alterada."})
        if inst is None and status not in (StatusOS.ABERTA, StatusOS.EM_ANDAMENTO, StatusOS.CONCLUIDA):
            raise serializers.ValidationError({"status": "Status inicial inválido."})
        if status == StatusOS.CONCLUIDA and not realizada:
            raise serializers.ValidationError({"realizada_em": "Informe a data de realização para concluir a OS."})
        if realizada and proxima and proxima < realizada:
            raise serializers.ValidationError(
                {"proxima_prevista": "A próxima manutenção deve ser igual ou posterior à realização."}
            )
        if "descricao" in dados and dados["descricao"] is not None:
            dados["descricao"] = dados["descricao"].strip()
        if inst is None and not dados.get("descricao"):
            raise serializers.ValidationError({"descricao": "Descreva o problema ou serviço."})
        return dados
