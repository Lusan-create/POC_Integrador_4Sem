from django.contrib import admin

from .models import LogAuditoria


@admin.register(LogAuditoria)
class LogAuditoriaAdmin(admin.ModelAdmin):
    list_display = ["criado_em", "usuario_email", "acao", "entidade", "entidade_id", "descricao", "ip"]
    list_filter = ["acao", "entidade"]
    search_fields = ["usuario_email", "descricao"]

    # Logs são somente leitura, inclusive no admin.
    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False
