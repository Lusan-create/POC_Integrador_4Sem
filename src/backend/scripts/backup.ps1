<#
  RS05 — Gera uma cópia de segurança do banco PostgreSQL (contêiner Docker).
  Uso:  .\scripts\backup.ps1
  O arquivo é salvo em backend\backups\gestao_ativos_AAAAMMDD_HHMMSS.dump
  O pg_dump roda dentro do contêiner "banco" (docker-compose.yml); as credenciais vêm do backend\.env.
#>
$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
$cfg = @{}
Get-Content (Join-Path $raiz ".env") | Where-Object { $_ -match '^\s*([A-Z_]+)\s*=\s*(.*)$' } | ForEach-Object {
    $cfg[$Matches[1]] = $Matches[2].Trim()
}
$conteiner = "gestao_ativos_banco"
$pasta = Join-Path $raiz "backups"
New-Item -ItemType Directory -Force $pasta | Out-Null
$nome = "{0}_{1}.dump" -f $cfg.DB_NOME, (Get-Date -Format "yyyyMMdd_HHmmss")
$arquivo = Join-Path $pasta $nome

docker exec $conteiner pg_dump -U $cfg.DB_USUARIO -d $cfg.DB_NOME -F c -f "/tmp/$nome"
if ($LASTEXITCODE -ne 0) { throw "pg_dump falhou (código $LASTEXITCODE). O contêiner está rodando? (docker compose up -d)" }
docker cp "${conteiner}:/tmp/$nome" $arquivo
if ($LASTEXITCODE -ne 0) { throw "Falha ao copiar o backup do contêiner." }
docker exec $conteiner rm -f "/tmp/$nome" | Out-Null

$tamanho = [math]::Round((Get-Item $arquivo).Length / 1KB, 1)
Write-Host "Backup criado: $arquivo ($tamanho KB)"
