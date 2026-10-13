<#
  RS05 — Restaura o banco a partir de um backup gerado por backup.ps1.
  Uso:  .\scripts\restaurar.ps1                      (usa o backup mais recente)
        .\scripts\restaurar.ps1 -Arquivo caminho.dump
  ATENÇÃO: substitui os dados atuais do banco pelos dados do backup.
#>
param([string]$Arquivo)
$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
$cfg = @{}
Get-Content (Join-Path $raiz ".env") | Where-Object { $_ -match '^\s*([A-Z_]+)\s*=\s*(.*)$' } | ForEach-Object {
    $cfg[$Matches[1]] = $Matches[2].Trim()
}
$pgBin = if ($env:PG_BIN) { $env:PG_BIN } else { "C:\Program Files\PostgreSQL\16\bin" }
if (-not $Arquivo) {
    $Arquivo = Get-ChildItem (Join-Path $raiz "backups") -Filter *.dump | Sort-Object LastWriteTime -Descending |
        Select-Object -First 1 -ExpandProperty FullName
    if (-not $Arquivo) { throw "Nenhum backup encontrado em backend\backups." }
}
Write-Host "Restaurando $Arquivo ..."
$env:PGPASSWORD = $cfg.DB_SENHA
try {
    & "$pgBin\pg_restore.exe" -h $cfg.DB_HOST -p $cfg.DB_PORTA -U $cfg.DB_USUARIO -d $cfg.DB_NOME --clean --if-exists --no-owner $Arquivo
    if ($LASTEXITCODE -ne 0) { throw "pg_restore falhou (código $LASTEXITCODE)" }
} finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}
Write-Host "Restauração concluída."
