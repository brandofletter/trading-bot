# start_all.ps1

$ProjectRoot = "C:\Users\brand\OneDrive\Desktop\quant_lab"
$FrontendRoot = Join-Path $ProjectRoot "dashboard_frontend"
$VenvActivate = Join-Path $ProjectRoot "venv\Scripts\Activate.ps1"
$PidFile = Join-Path $ProjectRoot "run_pids.json"

function Start-ManagedProcess {
    param(
        [string]$Name,
        [string]$WorkingDir,
        [string]$Command
    )

    $wrapped = @"
Set-Location '$WorkingDir'
& '$VenvActivate'
$Command
"@

    $proc = Start-Process powershell `
        -ArgumentList "-NoExit", "-Command", $wrapped `
        -WorkingDirectory $WorkingDir `
        -PassThru

    return [PSCustomObject]@{
        name = $Name
        pid  = $proc.Id
    }
}

Write-Host "Starting Quant Lab stack..." -ForegroundColor Cyan

$processes = @()

# Research engine
$processes += Start-ManagedProcess `
    -Name "continuous_research" `
    -WorkingDir $ProjectRoot `
    -Command "python -m main.continuous_research"

Start-Sleep -Seconds 2

# Paper trading engine
$processes += Start-ManagedProcess `
    -Name "continuous_paper_trading" `
    -WorkingDir $ProjectRoot `
    -Command "python -m main.continuous_paper_trading"

Start-Sleep -Seconds 2

# Backend API
$processes += Start-ManagedProcess `
    -Name "backend_api" `
    -WorkingDir $ProjectRoot `
    -Command "uvicorn dashboard.api_server:app --reload"

Start-Sleep -Seconds 3

# Frontend
$frontendWrapped = @"
Set-Location '$FrontendRoot'
npm start
"@

$frontendProc = Start-Process powershell `
    -ArgumentList "-NoExit", "-Command", $frontendWrapped `
    -WorkingDirectory $FrontendRoot `
    -PassThru

$processes += [PSCustomObject]@{
    name = "frontend"
    pid  = $frontendProc.Id
}

# Save PIDs
$processes | ConvertTo-Json | Set-Content $PidFile

Write-Host "All processes started." -ForegroundColor Green
Write-Host "PID file saved to $PidFile" -ForegroundColor Yellow

Start-Sleep -Seconds 5
Start-Process "http://localhost:3000"