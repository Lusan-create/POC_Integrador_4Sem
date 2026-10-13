from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView

from ativos.views import (
    AtivoViewSet, CategoriaViewSet, LocalizacaoViewSet, ManutencaoViewSet, MovimentacaoViewSet, painel,
)
from auditoria.views import LogAuditoriaViewSet
from contas.views import LoginView, UsuarioViewSet, eu

rotas = DefaultRouter()
rotas.register("ativos", AtivoViewSet, basename="ativo")
rotas.register("categorias", CategoriaViewSet, basename="categoria")
rotas.register("localizacoes", LocalizacaoViewSet, basename="localizacao")
rotas.register("movimentacoes", MovimentacaoViewSet, basename="movimentacao")
rotas.register("manutencoes", ManutencaoViewSet, basename="manutencao")
rotas.register("usuarios", UsuarioViewSet, basename="usuario")
rotas.register("logs", LogAuditoriaViewSet, basename="log")

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/auth/login/", LoginView.as_view(), name="login"),
    path("api/auth/renovar/", TokenRefreshView.as_view(), name="renovar-token"),
    path("api/auth/eu/", eu, name="eu"),
    path("api/painel/", painel, name="painel"),
    path("api/", include(rotas.urls)),
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="docs"),
]
