# AutoCreat Server — Windows Installation Script
# Requires: Windows 10 (1903+) or Windows 11, PowerShell 5.1+
# Run as Administrator for best results:
#   Right-click PowerShell → "Run as Administrator"
#   Then: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#         .\scripts\install-windows.ps1

#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Colours ──────────────────────────────────────────────────────────────────
function Write-Step  { Write-Host "`n▶ $args" -ForegroundColor Cyan }
function Write-Ok    { Write-Host "  ✓ $args" -ForegroundColor Green }
function Write-Warn  { Write-Host "  ⚠ $args" -ForegroundColor Yellow }
function Write-Fatal { Write-Host "`n✗ ERROR: $args" -ForegroundColor Red; exit 1 }

# ── Paths ─────────────────────────────────────────────────────────────────────
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ServerDir = Split-Path -Parent $ScriptDir
$GoVersion = "1.23.5"
$GoMinMajor = 1
$GoMinMinor = 23

# ── Helpers ───────────────────────────────────────────────────────────────────

function Has-Command($cmd) {
    return $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Go-Ok {
    if (-not (Has-Command "go")) { return $false }
    $ver = (go version 2>$null) -replace '.*go(\d+\.\d+).*','$1'
    if ($ver -match '(\d+)\.(\d+)') {
        $maj = [int]$matches[1]; $min = [int]$matches[2]
        return ($maj -gt $GoMinMajor) -or ($maj -eq $GoMinMajor -and $min -ge $GoMinMinor)
    }
    return $false
}

function Generate-Secret {
    $bytes = New-Object byte[] 32
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    return ($bytes | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' +
                [System.Environment]::GetEnvironmentVariable('Path','User')
}

function Has-Winget {
    return Has-Command "winget"
}

function Has-Choco {
    return Has-Command "choco"
}

# ── Step 1: Ensure winget or chocolatey ──────────────────────────────────────

function Ensure-PackageManager {
    if (Has-Winget) {
        Write-Ok "winget is available"
        $script:PkgMgr = 'winget'
        return
    }
    if (Has-Choco) {
        Write-Ok "Chocolatey is available"
        $script:PkgMgr = 'choco'
        return
    }

    Write-Step "Installing Chocolatey (winget not found)"
    Write-Warn "This requires an internet connection and Administrator privileges."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = `
        [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression (
        (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
    )
    Refresh-Path
    if (-not (Has-Choco)) { Write-Fatal "Package manager installation failed. Install Chocolatey manually: https://chocolatey.org/install" }
    $script:PkgMgr = 'choco'
    Write-Ok "Chocolatey installed"
}

# ── Step 2: Install Go ────────────────────────────────────────────────────────

function Install-Go {
    if (Go-Ok) {
        $v = (go version) -replace '.*go([0-9.]+).*','$1'
        Write-Ok "Go $v already installed (>= $GoMinMajor.$GoMinMinor)"
        return
    }

    Write-Step "Installing Go $GoVersion"

    switch ($script:PkgMgr) {
        'winget' {
            winget install --id GoLang.Go --version $GoVersion --accept-package-agreements --accept-source-agreements
        }
        'choco' {
            choco install golang --version $GoVersion -y
        }
    }

    Refresh-Path

    if (-not (Go-Ok)) {
        Write-Warn "Go not found in PATH after install. You may need to restart your terminal."
        Write-Warn "Then re-run: .\scripts\install-windows.ps1"
        Write-Fatal "Go installation failed or PATH not updated."
    }
    Write-Ok "Go $GoVersion installed"
}

# ── Step 3: Install PostgreSQL ────────────────────────────────────────────────

function Install-PostgreSQL {
    if (Has-Command "psql") {
        Write-Ok "PostgreSQL client already installed"
        return
    }

    Write-Step "Installing PostgreSQL 16"

    switch ($script:PkgMgr) {
        'winget' {
            winget install --id PostgreSQL.PostgreSQL.16 --accept-package-agreements --accept-source-agreements
        }
        'choco' {
            choco install postgresql16 --params '/Password:postgres' -y
        }
    }

    Refresh-Path

    # Add pg bin to PATH if not already present
    $pgPaths = @(
        'C:\Program Files\PostgreSQL\16\bin',
        'C:\Program Files\PostgreSQL\15\bin',
        'C:\Program Files\PostgreSQL\14\bin'
    )
    foreach ($p in $pgPaths) {
        if (Test-Path $p) {
            $env:Path = "$p;$env:Path"
            $userPath = [System.Environment]::GetEnvironmentVariable('Path','User')
            if ($userPath -notlike "*$p*") {
                [System.Environment]::SetEnvironmentVariable('Path', "$p;$userPath", 'User')
                Write-Ok "Added $p to user PATH"
            }
            break
        }
    }

    Write-Ok "PostgreSQL installed"
}

# ── Step 4: Start PostgreSQL service ──────────────────────────────────────────

function Start-PostgreSQLService {
    Write-Step "Starting PostgreSQL service"

    $pgServices = Get-Service -Name 'postgresql*' -ErrorAction SilentlyContinue
    if (-not $pgServices) {
        Write-Warn "No PostgreSQL Windows service found. It may have been installed without a service."
        Write-Warn "Start PostgreSQL manually and re-run this script."
        return
    }

    foreach ($svc in $pgServices) {
        if ($svc.Status -eq 'Running') {
            Write-Ok "$($svc.Name) is already running"
            return
        }
        try {
            Start-Service -Name $svc.Name
            Write-Ok "$($svc.Name) started"
            return
        } catch {
            Write-Warn "Could not start $($svc.Name): $_"
        }
    }
}

# ── Step 5: Database setup ────────────────────────────────────────────────────

function Setup-Database {
    Write-Step "Configuring PostgreSQL database"

    Write-Host ""
    Write-Host "  Enter your PostgreSQL connection details."
    Write-Host "  Press Enter to accept defaults shown in brackets."
    Write-Host ""

    $dbHost = Read-Host "  Host     [localhost]"
    if (-not $dbHost) { $dbHost = 'localhost' }

    $dbPort = Read-Host "  Port     [5432]"
    if (-not $dbPort) { $dbPort = '5432' }

    $dbUser = Read-Host "  Admin user [postgres]"
    if (-not $dbUser) { $dbUser = 'postgres' }

    $dbPassSecure = Read-Host "  Admin password" -AsSecureString
    $dbPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbPassSecure))

    $dbName = Read-Host "  Database name [autocreat]"
    if (-not $dbName) { $dbName = 'autocreat' }

    # Test connection
    $env:PGPASSWORD = $dbPass
    try {
        $null = & psql -h $dbHost -p $dbPort -U $dbUser -c '\q' 2>&1
        if ($LASTEXITCODE -ne 0) { throw "psql exited with $LASTEXITCODE" }
        Write-Ok "Connected to PostgreSQL"
    } catch {
        Write-Fatal "Cannot connect to PostgreSQL at ${dbHost}:${dbPort} as '${dbUser}'.`nCheck credentials and ensure the service is running."
    }

    # Create main database if missing
    $exists = & psql -h $dbHost -p $dbPort -U $dbUser -tAc "SELECT 1 FROM pg_database WHERE datname='$dbName'" 2>$null
    if ($exists -match '1') {
        Write-Ok "Database '$dbName' already exists"
    } else {
        & psql -h $dbHost -p $dbPort -U $dbUser -c "CREATE DATABASE `"$dbName`";"
        if ($LASTEXITCODE -ne 0) { Write-Fatal "Failed to create database '$dbName'" }
        Write-Ok "Database '$dbName' created"
    }

    # Create test database if missing (used by go test ./...)
    $testDbName = "${dbName}_test"
    $testExists = & psql -h $dbHost -p $dbPort -U $dbUser -tAc "SELECT 1 FROM pg_database WHERE datname='$testDbName'" 2>$null
    if ($testExists -match '1') {
        Write-Ok "Test database '$testDbName' already exists"
    } else {
        & psql -h $dbHost -p $dbPort -U $dbUser -c "CREATE DATABASE `"$testDbName`";"
        if ($LASTEXITCODE -ne 0) { Write-Fatal "Failed to create test database '$testDbName'" }
        Write-Ok "Test database '$testDbName' created"
    }

    $script:CfgDbUrl = "postgres://${dbUser}:${dbPass}@${dbHost}:${dbPort}/${dbName}?sslmode=disable"

    $portInput = Read-Host "  Server port [8081]"
    $script:CfgPort = if ($portInput) { $portInput } else { '8081' }
}

# ── Step 6: Create .env ───────────────────────────────────────────────────────

function Create-Env {
    Write-Step "Creating .env file"

    $envPath = Join-Path $ServerDir '.env'
    if (Test-Path $envPath) {
        Write-Warn ".env already exists — writing to .env.new instead. Review and rename it."
        $envPath = Join-Path $ServerDir '.env.new'
    }

    $jwtSecret        = Generate-Secret
    $jwtRefreshSecret = Generate-Secret

    $content = @"
# -- Database -----------------------------------------------------------------
DATABASE_URL=$($script:CfgDbUrl)

# -- JWT Authentication -------------------------------------------------------
JWT_SECRET=$jwtSecret
JWT_REFRESH_SECRET=$jwtRefreshSecret
ACCESS_TOKEN_TTL=15m
REFRESH_TOKEN_TTL=168h

# -- Server -------------------------------------------------------------------
PORT=$($script:CfgPort)
ENV=development

# -- CORS (comma-separated list of allowed origins) ---------------------------
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:$($script:CfgPort)

# -- Rate Limiting ------------------------------------------------------------
RATE_LIMIT=100
RATE_LIMIT_BURST=200

# -- DB Connection Pool -------------------------------------------------------
DB_MAX_IDLE_CONNS=10
DB_MAX_OPEN_CONNS=100
DB_CONN_MAX_LIFETIME=1h

# -- Redis (optional -- comment out to disable caching) -----------------------
# REDIS_URL=redis://localhost:6379

# -- Demo data -----------------------------------------------------------------
# Seeding runs automatically when ENV=development (the default).
# Set SEED_DB=false to suppress it, or SEED_DB=true to force it
# in any environment.
# SEED_DB=false
"@

    Set-Content -Path $envPath -Value $content -Encoding UTF8
    Write-Ok ".env written to $envPath"
}

# ── Step 7: Download Go modules ───────────────────────────────────────────────

function Download-Deps {
    Write-Step "Downloading Go module dependencies"
    Push-Location $ServerDir
    try {
        & go mod download
        & go mod verify
    } finally {
        Pop-Location
    }
    Write-Ok "Dependencies ready"
}

# ── Step 8: Build binary ──────────────────────────────────────────────────────

function Build-Binary {
    Write-Step "Building server binary"

    $binDir = Join-Path $ServerDir 'bin'
    if (-not (Test-Path $binDir)) { New-Item -ItemType Directory -Path $binDir | Out-Null }

    Push-Location $ServerDir
    try {
        $env:CGO_ENABLED = '0'
        & go build -ldflags="-s -w" -o (Join-Path $binDir 'server.exe') ./cmd/server
        if ($LASTEXITCODE -ne 0) { Write-Fatal "go build failed" }
    } finally {
        Pop-Location
    }

    Write-Ok "Binary built: $binDir\server.exe"
}

# ── Done ──────────────────────────────────────────────────────────────────────

function Write-Summary {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "  Installation complete!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Review config:  $ServerDir\.env"
    Write-Host ""
    Write-Host "  Start server:   .\scripts\server-windows.ps1 start"
    Write-Host "  Stop server:    .\scripts\server-windows.ps1 stop"
    Write-Host "  View logs:      .\scripts\server-windows.ps1 logs"
    Write-Host ""
    Write-Host "  Database migrations run automatically on first start."
    Write-Host ""
}

# ── Entrypoint ────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  AutoCreat Server - Windows Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$script:PkgMgr = ''
$script:CfgDbUrl = ''
$script:CfgPort = '8081'

Ensure-PackageManager
Install-Go
Install-PostgreSQL
Start-PostgreSQLService
Setup-Database
Create-Env
Download-Deps
Build-Binary
Write-Summary
