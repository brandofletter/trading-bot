# stop_all.ps1

$ProjectRoot = "C:\Users\brand\OneDrive\Desktop\quant_lab"
$PidFile = Join-Path $ProjectRoot "run_pids.json"

if (-not (Test-Path $PidFile)) {
    Write-Host "No PID file found. Nothing to stop." -ForegroundColor Yellow
    exit
}

try {
    $processes = Get-Content $PidFile | ConvertFrom-Json
} catch {
    Write-Host "Could not read PID file." -ForegroundColor Red
    exit 1
}

foreach ($proc in $processes) {
    try {
        $p = Get-Process -Id $proc.pid -ErrorAction Stop
        Stop-Process -Id $proc.pid -Force
        Write-Host "Stopped $($proc.name) (PID $($proc.pid))" -ForegroundColor Green
    } catch {
        Write-Host "Process $($proc.name) (PID $($proc.pid)) was not running." -ForegroundColor Yellow
    }
}

Remove-Item $PidFile -Force
Write-Host "Quant Lab stack stopped." -ForegroundColor Cyan