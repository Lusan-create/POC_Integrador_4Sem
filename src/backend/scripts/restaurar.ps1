<#
  RS05 — Restaura o banco a partir de um backup gerado por backup.ps1.
  Uso:  .\scripts\restaurar.ps1                      (usa o backup mais recente)
        .\scripts\restaurar.ps1 -Arquivo caminho.dump
  O pg_restore roda dentro do contêiner "banco" (docker-compose.yml).
  ATENÇÃO: substitui os dados atuais do banco pelos dados do backup.
#>
param([string]$Arquivo)
$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
$cfg = @{}
Get-Content (Join-Path $raiz ".env") | Where-Object { $_ -match '^\s*([A-Z_]+)\s*=\s*(.*)$' } | ForEach-Object {
    $cfg[$Matches[1]] = $Matches[2].Trim()
}
$conteiner = "gestao_ativos_banco"
if (-not $Arquivo) {
    $Arquivo = Get-ChildItem (Join-Path $raiz "backups") -Filter *.dump | Sort-Object LastWriteTime -Descending |
        Select-Object -First 1 -ExpandProperty FullName
    if (-not $Arquivo) { throw "Nenhum backup encontrado em backend\backups." }
}
Write-Host "Restaurando $Arquivo ..."
docker cp $Arquivo "${conteiner}:/tmp/restaurar.dump"
if ($LASTEXITCODE -ne 0) { throw "Falha ao copiar o backup para o contêiner. Ele está rodando? (docker compose up -d)" }
try {
    docker exec $conteiner pg_restore -U $cfg.DB_USUARIO -d $cfg.DB_NOME --clean --if-exists --no-owner /tmp/restaurar.dump
    if ($LASTEXITCODE -ne 0) { throw "pg_restore falhou (código $LASTEXITCODE)" }
} finally {
    docker exec $conteiner rm -f /tmp/restaurar.dump | Out-Null
}
Write-Host "Restauração concluída."
