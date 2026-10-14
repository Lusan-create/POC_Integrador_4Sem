from django.contrib import admin

from .models import Ativo, Categoria, Localizacao, Manutencao, Movimentacao

admin.site.site_header = "Gestão de Ativos — Administração"


@admin.register(Categoria)
class CategoriaAdmin(admin.ModelAdmin):
    search_fields = ["nome"]


@admin.register(Localizacao)
class LocalizacaoAdmin(admin.ModelAdmin):
    list_display = ["nome", "descricao"]
    search_fields = ["nome"]


@admin.register(Ativo)
class AtivoAdmin(admin.ModelAdmin):
    list_display = ["identificacao", "nome", "categoria", "localizacao", "responsavel", "status"]
    list_filter = ["status", "categoria", "localizacao"]
    search_fields = ["identificacao", "nome"]


@admin.register(Movimentacao)
class MovimentacaoAdmin(admin.ModelAdmin):
    list_display = ["ativo", "origem", "destino", "registrado_por", "realizada_em"]
    list_filter = ["destino"]


@admin.register(Manutencao)
class ManutencaoAdmin(admin.ModelAdmin):
    list_display = ["id", "ativo", "tipo", "status", "aberta_em", "realizada_em", "custo"]
    list_filter = ["status", "tipo"]
