from django.contrib.auth.base_user import AbstractBaseUser, BaseUserManager
from django.db import models
from django.db.models.functions import Now
from django.utils import timezone


class Cargo(models.TextChoices):
    ADMIN = "admin", "Administrador"
    USER = "user", "Usuário"


class UsuarioManager(BaseUserManager):
    use_in_migrations = True

    def get_queryset(self):
        # Usuários excluídos (soft delete) não aparecem nas consultas padrão.
        return super().get_queryset().filter(deletado_em__isnull=True)

    def todos(self):
        return super().get_queryset()

    def create_user(self, email, senha=None, **campos):
        if not email:
            raise ValueError("O e-mail é obrigatório.")
        usuario = self.model(email=self.normalize_email(email).lower(), **campos)
        usuario.set_password(senha)
        usuario.save(using=self._db)
        return usuario

    def create_superuser(self, email, password=None, **campos):
        campos["cargo"] = Cargo.ADMIN
        return self.create_user(email, password, **campos)


class Usuario(AbstractBaseUser):
    """Tabela USUARIO do modelo físico. Login é feito pelo e-mail."""

    nome = models.CharField(max_length=120)
    email = models.EmailField(max_length=255, unique=True)
    # Campo de senha do Django (hash PBKDF2) gravado na coluna senha_hash do DER.
    password = models.CharField("senha", max_length=255, db_column="senha_hash")
    data_nascimento = models.DateField(null=True, blank=True)
    cargo = models.CharField(max_length=10, choices=Cargo.choices, default=Cargo.USER)
    criado_em = models.DateTimeField(default=timezone.now, db_default=Now())
    atualizado_em = models.DateTimeField(auto_now=True, db_default=Now())
    deletado_em = models.DateTimeField(null=True, blank=True)

    # Coluna last_login do AbstractBaseUser não faz parte do DER.
    last_login = None

    objects = UsuarioManager()

    USERNAME_FIELD = "email"
    EMAIL_FIELD = "email"
    REQUIRED_FIELDS = ["nome"]

    class Meta:
        db_table = "usuario"
        ordering = ["nome"]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(cargo__in=["admin", "user"]),
                name="ck_usuario_cargo",
            ),
            models.CheckConstraint(
                condition=models.Q(data_nascimento__isnull=True)
                | models.Q(data_nascimento__lte=Now()),
                name="ck_usuario_data_nascimento",
            ),
        ]

    def __str__(self):
        return f"{self.nome} <{self.email}>"

    # --- integração com o sistema de autenticação do Django ---
    @property
    def is_active(self):
        return self.deletado_em is None

    @property
    def is_admin(self):
        return self.cargo == Cargo.ADMIN

    @property
    def is_staff(self):
        return self.is_admin

    @property
    def is_superuser(self):
        return self.is_admin

    def has_perm(self, perm, obj=None):
        return self.is_active and self.is_admin

    def has_module_perms(self, app_label):
        return self.is_active and self.is_admin
