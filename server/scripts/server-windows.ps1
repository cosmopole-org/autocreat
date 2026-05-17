# AutoCreat Server — Windows Process Manager
# Usage: .\scripts\server-windows.ps1 {start|stop|restart|status|logs|build}
#
# If you see "execution of scripts is disabled", run first:
#   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [ValidateSet('start','stop','restart','status','logs','build','help')]
    [string]$Command = 'help',

    [Parameter(Position=1)]
    [string]$Option = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Colours ──────────────────────────────────────────────────────────────────
function Write-Info  { Write-Host "▶ $args" -ForegroundColor Cyan }
function Write-Ok    { Write-Host "✓ $args" -ForegroundColor Green }
function Write-Warn  { Write-Host "⚠ $args" -ForegroundColor Yellow }
function Write-Fatal { Write-Host "✗ $args" -ForegroundColor Red; exit 1 }

# ── Paths ─────────────────────────────────────────────────────────────────────
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ServerDir = Split-Path -Parent $ScriptDir
$BinPath   = Join-Path $ServerDir 'bin\server.exe'
$PidFile   = Join-Path $ServerDir 'tmp\server.pid'
$LogFile   = Join-Path $ServerDir 'tmp\server.log'
$EnvFile   = Join-Path $ServerDir '.env'
$TmpDir    = Join-Path $ServerDir 'tmp'

if (-not (Test-Path $TmpDir)) { New-Item -ItemType Directory -Path $TmpDir | Out-Null }

# ── Helpers ───────────────────────────────────────────────────────────────────

function Is-Running {
    if (-not (Test-Path $PidFile)) { return $false }
    $pid = Get-Content $PidFile -ErrorAction SilentlyContinue
    if (-not $pid) { return $false }
    try {
        $proc = Get-Process -Id ([int]$pid) -ErrorAction SilentlyContinue
        return $null -ne $proc
    } catch { return $false }
}

function Get-Pid {
    if (Test-Path $PidFile) { return (Get-Content $PidFile).Trim() }
    return ''
}

function Read-EnvFile {
    $result = @{}
    if (-not (Test-Path $EnvFile)) { return $result }
    foreach ($line in Get-Content $EnvFile) {
        if ($line -match '^\s*#' -or $line -notmatch '=') { continue }
        $parts = $line -split '=', 2
        $key   = $parts[0].Trim()
        $value = $parts[1].Trim()
        $result[$key] = $value
    }
    return $result
}

function Check-Env {
    if (-not (Test-Path $EnvFile)) {
        Write-Fatal ".env not found at $EnvFile`nRun .\scripts\install-windows.ps1 first."
    }
}

function Check-Go {
    if (-not (Get-Command 'go' -ErrorAction SilentlyContinue)) {
        # Refresh PATH and try again
        $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' +
                    [System.Environment]::GetEnvironmentVariable('Path','User')
        if (-not (Get-Command 'go' -ErrorAction SilentlyContinue)) {
            Write-Fatal "Go not found in PATH. Run .\scripts\install-windows.ps1 first."
        }
    }
}

function Binary-Needs-Build {
    if (-not (Test-Path $BinPath)) { return $true }
    $binTime = (Get-Item $BinPath).LastWriteTime
    $newer = Get-ChildItem -Path $ServerDir -Recurse -Filter '*.go' |
             Where-Object { $_.LastWriteTime -gt $binTime } |
             Select-Object -First 1
    return $null -ne $newer
}

# ── Build ─────────────────────────────────────────────────────────────────────

function Invoke-Build {
    Write-Info "Building server binary"
    Check-Go
    Check-Env

    $binDir = Join-Path $ServerDir 'bin'
    if (-not (Test-Path $binDir)) { New-Item -ItemType Directory -Path $binDir | Out-Null }

    Push-Location $ServerDir
    try {
        $env:CGO_ENABLED = '0'
        & go build -ldflags="-s -w" -o $BinPath ./cmd/server
        if ($LASTEXITCODE -ne 0) { Write-Fatal "go build failed (exit $LASTEXITCODE)" }
    } finally {
        Pop-Location
    }

    Write-Ok "Built: $BinPath"
}

# ── Start ─────────────────────────────────────────────────────────────────────

function Invoke-Start {
    Check-Env

    if (Is-Running) {
        Write-Ok "Server is already running (PID $(Get-Pid))"
        return
    }

    # Clean stale PID file
    if ((Test-Path $PidFile) -and -not (Is-Running)) {
        Write-Warn "Removing stale PID file"
        Remove-Item $PidFile -Force
    }

    Check-Go

    if (Binary-Needs-Build) {
        Write-Info "Binary outdated or missing — building first..."
        Invoke-Build
    }

    Write-Info "Starting AutoCreat server"

    # Read env vars from .env and build the environment block
    $cfg = Read-EnvFile
    $port = if ($cfg.ContainsKey('PORT')) { $cfg['PORT'] } else { '8081' }

    # Build environment variable list for the new process
    $procEnv = [System.Collections.Generic.Dictionary[string,string]]::new()
    foreach ($kv in $cfg.GetEnumerator()) {
        $procEnv[$kv.Key] = $kv.Value
    }
    # Inherit current PATH so the binary can find system libs
    $procEnv['PATH'] = $env:Path

    # Start the process detached, redirect output to log file
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName               = $BinPath
    $psi.WorkingDirectory       = $ServerDir
    $psi.UseShellExecute        = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.CreateNoWindow         = $true

    foreach ($kv in $procEnv.GetEnumerator()) {
        $psi.EnvironmentVariables[$kv.Key] = $kv.Value
    }

    $proc = [System.Diagnostics.Process]::new()
    $proc.StartInfo = $psi

    # Stream output asynchronously to log file
    $logStream = [System.IO.StreamWriter]::new($LogFile, $true)
    $logStream.AutoFlush = $true

    $proc.OutputDataReceived += {
        param($s,$e)
        if ($null -ne $e.Data) { $logStream.WriteLine($e.Data) }
    }
    $proc.ErrorDataReceived += {
        param($s,$e)
        if ($null -ne $e.Data) { $logStream.WriteLine($e.Data) }
    }

    $null = $proc.Start()
    $proc.BeginOutputReadLine()
    $proc.BeginErrorReadLine()

    Set-Content -Path $PidFile -Value $proc.Id

    Start-Sleep -Seconds 2

    if (-not (Is-Running)) {
        Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
        $logStream.Close()
        $recent = Get-Content $LogFile -Tail 20 -ErrorAction SilentlyContinue
        Write-Fatal "Server failed to start. Recent log:`n$($recent -join "`n")"
    }

    Write-Ok "Server started (PID $($proc.Id))"
    Write-Host "  Listening on http://localhost:$port"
    Write-Host "  Log file:    $LogFile"
    Write-Host "  PID file:    $PidFile"
}

# ── Stop ──────────────────────────────────────────────────────────────────────

function Invoke-Stop {
    if (-not (Is-Running)) {
        if (Test-Path $PidFile) { Remove-Item $PidFile -Force }
        Write-Warn "Server is not running"
        return
    }

    $pid = [int](Get-Pid)
    Write-Info "Stopping server (PID $pid)"

    try {
        $proc = Get-Process -Id $pid -ErrorAction Stop
        $proc.CloseMainWindow() | Out-Null
        if (-not $proc.WaitForExit(10000)) {
            Write-Warn "Server did not stop gracefully after 10 s — force-killing"
            $proc.Kill()
            $proc.WaitForExit(3000) | Out-Null
        }
    } catch {
        Write-Warn "Process $pid not found (may have already stopped)"
    }

    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
    Write-Ok "Server stopped"
}

# ── Restart ───────────────────────────────────────────────────────────────────

function Invoke-Restart {
    Write-Info "Restarting server"
    Invoke-Stop
    Start-Sleep -Seconds 1
    Invoke-Start
}

# ── Status ────────────────────────────────────────────────────────────────────

function Invoke-Status {
    if (Is-Running) {
        $pid  = Get-Pid
        $cfg  = Read-EnvFile
        $port = if ($cfg.ContainsKey('PORT')) { $cfg['PORT'] } else { '8081' }

        Write-Ok "Server is RUNNING (PID $pid, port $port)"
        Write-Host ""

        try {
            $proc = Get-Process -Id ([int]$pid)
            Write-Host "  Started: $($proc.StartTime)"
            Write-Host "  Memory:  $([math]::Round($proc.WorkingSet64 / 1MB, 1)) MB"
        } catch {}

        Write-Host "  Log:     $LogFile"

        try {
            $response = Invoke-WebRequest -Uri "http://localhost:$port/health" `
                -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
            Write-Host "  Health:  $($response.Content)"
        } catch {
            Write-Host "  Health:  unreachable"
        }
    } else {
        if (Test-Path $PidFile) { Remove-Item $PidFile -Force }
        Write-Host "● Server is STOPPED" -ForegroundColor Yellow
    }
}

# ── Logs ──────────────────────────────────────────────────────────────────────

function Invoke-Logs {
    if (-not (Test-Path $LogFile)) {
        Write-Fatal "No log file found at $LogFile"
    }
    Write-Host "-- $LogFile --"
    if ($Option -eq '-f' -or $Option -eq '--follow') {
        Get-Content $LogFile -Wait -Tail 50
    } else {
        Get-Content $LogFile -Tail 100
    }
}

# ── Help ──────────────────────────────────────────────────────────────────────

function Invoke-Help {
    Write-Host ""
    Write-Host "AutoCreat Server Manager — Windows" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Usage: .\scripts\server-windows.ps1 <command> [option]"
    Write-Host ""
    Write-Host "  Commands:"
    Write-Host "    start       Build (if needed) and start the server"
    Write-Host "    stop        Gracefully stop the running server"
    Write-Host "    restart     Stop then start"
    Write-Host "    status      Show running status and health"
    Write-Host "    logs        Print last 100 log lines"
    Write-Host "    logs -f     Follow log output in real time (Ctrl+C to stop)"
    Write-Host "    build       Compile the server binary without starting"
    Write-Host "    help        Show this help"
    Write-Host ""
    Write-Host "  If scripts are blocked, run once:"
    Write-Host "    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned"
    Write-Host ""
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

switch ($Command) {
    'start'   { Invoke-Start   }
    'stop'    { Invoke-Stop    }
    'restart' { Invoke-Restart }
    'status'  { Invoke-Status  }
    'logs'    { Invoke-Logs    }
    'build'   { Invoke-Build   }
    default   { Invoke-Help    }
}
