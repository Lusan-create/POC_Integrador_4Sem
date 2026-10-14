from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from .models import Usuario


class UsuarioResumoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Usuario
        fields = ["id", "nome", "email"]


class UsuarioSerializer(serializers.ModelSerializer):
    senha = serializers.CharField(write_only=True, required=False, style={"input_type": "password"})
    cargo_exibicao = serializers.CharField(source="get_cargo_display", read_only=True)

    class Meta:
        model = Usuario
        fields = [
            "id", "nome", "email", "senha", "data_nascimento", "cargo", "cargo_exibicao",
            "criado_em", "atualizado_em",
        ]
        read_only_fields = ["criado_em", "atualizado_em"]

    def validate_email(self, valor):
        valor = valor.strip().lower()
        existente = Usuario.objects.todos().filter(email=valor)
        if self.instance:
            existente = existente.exclude(pk=self.instance.pk)
        if existente.exists():
            raise serializers.ValidationError("Já existe um usuário com este e-mail.")
        return valor

    def validate_nome(self, valor):
        valor = valor.strip()
        if len(valor) < 3:
            raise serializers.ValidationError("Informe o nome completo.")
        return valor

    def validate(self, dados):
        senha = dados.get("senha")
        if self.instance is None and not senha:
            raise serializers.ValidationError({"senha": "A senha é obrigatória no cadastro."})
        if senha:
            usuario_temp = self.instance or Usuario(email=dados.get("email", ""), nome=dados.get("nome", ""))
            try:
                validate_password(senha, usuario_temp)
            except DjangoValidationError as erro:
                raise serializers.ValidationError({"senha": list(erro.messages)})
        return dados

    def create(self, dados):
        senha = dados.pop("senha")
        return Usuario.objects.create_user(senha=senha, **dados)

    def update(self, instancia, dados):
        senha = dados.pop("senha", None)
        for campo, valor in dados.items():
            setattr(instancia, campo, valor)
        if senha:
            instancia.set_password(senha)
        instancia.save()
        return instancia


class PerfilSerializer(serializers.ModelSerializer):
    cargo_exibicao = serializers.CharField(source="get_cargo_display", read_only=True)

    class Meta:
        model = Usuario
        fields = ["id", "nome", "email", "cargo", "cargo_exibicao"]


class LoginSerializer(TokenObtainPairSerializer):
    """Login por e-mail e senha; devolve os tokens JWT e os dados do usuário."""

    default_error_messages = {"no_active_account": "E-mail ou senha inválidos."}

    def validate(self, attrs):
        attrs[self.username_field] = attrs.get(self.username_field, "").strip().lower()
        dados = super().validate(attrs)
        dados["usuario"] = PerfilSerializer(self.user).data
        return dados

    @classmethod
    def get_token(cls, usuario):
        token = super().get_token(usuario)
        token["nome"] = usuario.nome
        token["cargo"] = usuario.cargo
        return token
