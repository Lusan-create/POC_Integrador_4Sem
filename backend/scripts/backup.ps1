<#
  RS05 — Gera uma cópia de segurança do banco PostgreSQL.
  Uso:  .\scripts\backup.ps1
  O arquivo é salvo em backend\backups\gestao_ativos_AAAAMMDD_HHMMSS.dump
  As credenciais são lidas do backend\.env (nunca ficam no script).
#>
$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
$cfg = @{}
Get-Content (Join-Path $raiz ".env") | Where-Object { $_ -match '^\s*([A-Z_]+)\s*=\s*(.*)$' } | ForEach-Object {
    $cfg[$Matches[1]] = $Matches[2].Trim()
}
$pgBin = if ($env:PG_BIN) { $env:PG_BIN } else { "C:\Program Files\PostgreSQL\16\bin" }
$pasta = Join-Path $raiz "backups"
New-Item -ItemType Directory -Force $pasta | Out-Null
$arquivo = Join-Path $pasta ("{0}_{1}.dump" -f $cfg.DB_NOME, (Get-Date -Format "yyyyMMdd_HHmmss"))

$env:PGPASSWORD = $cfg.DB_SENHA
try {
    & "$pgBin\pg_dump.exe" -h $cfg.DB_HOST -p $cfg.DB_PORTA -U $cfg.DB_USUARIO -d $cfg.DB_NOME -F c -f $arquivo
    if ($LASTEXITCODE -ne 0) { throw "pg_dump falhou (código $LASTEXITCODE)" }
} finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}
$tamanho = [math]::Round((Get-Item $arquivo).Length / 1KB, 1)
Write-Host "Backup criado: $arquivo ($tamanho KB)"
