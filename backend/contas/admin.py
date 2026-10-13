from django.contrib import admin

from .models import Usuario


@admin.register(Usuario)
class UsuarioAdmin(admin.ModelAdmin):
    list_display = ["nome", "email", "cargo", "criado_em", "deletado_em"]
    list_filter = ["cargo"]
    search_fields = ["nome", "email"]
    exclude = ["password"]
    readonly_fields = ["criado_em", "atualizado_em"]
