param(
    [string]$ProjectRoot = $PSScriptRoot,
    [string]$BackendModule = "dashboard.api_server:app",
    [int]$BackendPort = 8000,
    [int]$FrontendPort = 3000
)

$ErrorActionPreference = "Stop"

function Write-Step($msg) {
    Write-Host "`n=== $msg ===" -ForegroundColor Cyan
}

function Ensure-Command($name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        throw "Required command not found: $name"
    }
}

function Start-InNewWindow($title, $workingDir, $command) {
    Start-Process powershell.exe -ArgumentList @(
        "-NoExit",
        "-ExecutionPolicy", "Bypass",
        "-Command", "Set-Location '$workingDir'; `$host.UI.RawUI.WindowTitle = '$title'; $command"
    ) | Out-Null
}

Write-Step "Preparing Quant Lab"

$ProjectRoot = (Resolve-Path $ProjectRoot).Path
$FrontendDir = Join-Path $ProjectRoot "dashboard_frontend"
$RuntimeDir = Join-Path $ProjectRoot "runtime_status"

if (-not (Test-Path $ProjectRoot)) {
    throw "Project root not found: $ProjectRoot"
}
if (-not (Test-Path $FrontendDir)) {
    throw "Frontend folder not found: $FrontendDir"
}

New-Item -ItemType Directory -Force -Path $RuntimeDir | Out-Null

Ensure-Command python
Ensure-Command npm

Write-Step "Setting Quant Lab environment variables"

$env:PYTHONPATH = $ProjectRoot
$env:QUANT_LAB_RESEARCH_CMD       = "python -m main.continuous_research"
$env:QUANT_LAB_EQUITIES_PAPER_CMD = "python -m main.continuous_equities_paper"
$env:QUANT_LAB_EQUITIES_LIVE_CMD  = "python -m main.continuous_equities_live"
$env:QUANT_LAB_CRYPTO_PAPER_CMD   = "python -m main.continuous_crypto_paper"
$env:QUANT_LAB_CRYPTO_LIVE_CMD    = "python -m main.continuous_crypto_live"

# Live trading safeguard: leave false until you're ready.
if (-not $env:QUANT_LAB_ENABLE_LIVE_TRADING) {
    $env:QUANT_LAB_ENABLE_LIVE_TRADING = "false"
}

Write-Host "PYTHONPATH=$env:PYTHONPATH"
Write-Host "QUANT_LAB_ENABLE_LIVE_TRADING=$env:QUANT_LAB_ENABLE_LIVE_TRADING"

Write-Step "Installing missing backend dependencies if needed"
python -m pip install --disable-pip-version-check fastapi uvicorn python-dotenv ccxt pandas-market-calendars pytz | Out-Host

Write-Step "Installing frontend dependencies if needed"
Set-Location $FrontendDir
npm install | Out-Host

Write-Step "Starting backend"
$backendCmd = @"
`$env:PYTHONPATH='$ProjectRoot';
`$env:QUANT_LAB_RESEARCH_CMD='python -m main.continuous_research';
`$env:QUANT_LAB_EQUITIES_PAPER_CMD='python -m main.continuous_equities_paper';
`$env:QUANT_LAB_EQUITIES_LIVE_CMD='python -m main.continuous_equities_live';
`$env:QUANT_LAB_CRYPTO_PAPER_CMD='python -m main.continuous_crypto_paper';
`$env:QUANT_LAB_CRYPTO_LIVE_CMD='python -m main.continuous_crypto_live';
`$env:QUANT_LAB_ENABLE_LIVE_TRADING='$env:QUANT_LAB_ENABLE_LIVE_TRADING';
python -m uvicorn $BackendModule --host 127.0.0.1 --port $BackendPort --reload
"@
Start-InNewWindow "Quant Lab Backend" $ProjectRoot $backendCmd

Start-Sleep -Seconds 3

Write-Step "Starting frontend"
$frontendCmd = @"
`$env:BROWSER='none';
`$env:PORT='$FrontendPort';
npm start
"@
Start-InNewWindow "Quant Lab Frontend" $FrontendDir $frontendCmd

Start-Sleep -Seconds 6

Write-Step "Opening app"
Start-Process "http://127.0.0.1:$FrontendPort"

Write-Host "`nQuant Lab launch sequence completed." -ForegroundColor Green
Write-Host "Backend:  http://127.0.0.1:$BackendPort"
Write-Host "Frontend: http://127.0.0.1:$FrontendPort"
Write-Host ""
Write-Host "Live trading is currently set to: $env:QUANT_LAB_ENABLE_LIVE_TRADING"
Write-Host "Change it to true only when you are ready to allow live workers."