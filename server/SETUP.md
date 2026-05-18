# AutoCreat Server — Setup & Operations Guide

This guide covers installing dependencies, configuring the environment, and managing the server process on **Linux**, **macOS**, and **Windows**.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
   - [Linux](#linux)
   - [macOS](#macos)
   - [Windows](#windows)
3. [What the Install Script Does](#what-the-install-script-does)
4. [Environment Configuration (`.env`)](#environment-configuration-env)
5. [Server Management Commands](#server-management-commands)
6. [Running Migrations](#running-migrations)
7. [Seeding Demo Data](#seeding-demo-data)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

| Tool | Minimum version | Notes |
|------|----------------|-------|
| Go | 1.23 | Installed automatically by the install script |
| PostgreSQL | 14+ | Installed automatically; version 16 preferred |
| curl / PowerShell | any | Used by install scripts for downloads |
| Internet access | — | Required to download Go and packages |

Redis is **optional**. The server runs fine without it (caching is disabled automatically when `REDIS_URL` is unset).

---

## Quick Start

> **Run all scripts from inside the `server/` directory** unless stated otherwise.

### Linux

```bash
# 1. Make scripts executable
chmod +x scripts/install-linux.sh scripts/server-linux.sh

# 2. Install everything (Go, PostgreSQL, database, .env, binary)
./scripts/install-linux.sh

# 3. Start the server
./scripts/server-linux.sh start

# 4. Check it is running
./scripts/server-linux.sh status
```

**Supported distributions:** Ubuntu 20.04+, Debian 11+, Fedora 38+, RHEL/CentOS/AlmaLinux/Rocky 8+, Arch/Manjaro, openSUSE Leap 15+.

---

### macOS

```bash
# 1. Make scripts executable
chmod +x scripts/install-mac.sh scripts/server-mac.sh

# 2. Install everything (Homebrew if missing, Go, PostgreSQL, database, .env, binary)
./scripts/install-mac.sh

# 3. Start the server
./scripts/server-mac.sh start

# 4. Check it is running
./scripts/server-mac.sh status
```

**Requires:** macOS 12 Monterey or later. Both Intel and Apple Silicon (M1/M2/M3) are supported.

> **Note for Apple Silicon:** Homebrew installs to `/opt/homebrew`. The install script adds it to your shell profile automatically. If a new terminal does not find `go` or `psql`, restart your terminal or run `source ~/.zprofile`.

---

### Windows

Open **PowerShell** (preferably as Administrator for first-time setup):

```powershell
# 1. Allow local scripts to run (one-time, per user)
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

# 2. Install everything (winget/Chocolatey, Go, PostgreSQL, database, .env, binary)
.\scripts\install-windows.ps1

# 3. Start the server
.\scripts\server-windows.ps1 start

# 4. Check it is running
.\scripts\server-windows.ps1 status
```

**Requires:** Windows 10 (version 1903+) or Windows 11, PowerShell 5.1+.

> **winget vs Chocolatey:** The script uses `winget` if available (ships with Windows 11 and updated Windows 10). If not found, it installs Chocolatey automatically. To use Chocolatey explicitly, install it first from [chocolatey.org/install](https://chocolatey.org/install).

---

## What the Install Script Does

The install scripts run these steps in order:

| Step | Description |
|------|-------------|
| **1. Install Go** | Downloads and installs Go 1.23 if not already present (or < 1.23). Adds it to `$PATH` permanently in your shell profile. |
| **2. Install PostgreSQL** | Installs PostgreSQL 16 via the system package manager (apt/dnf/brew/winget/choco). Starts the service. |
| **3. Start PostgreSQL** | Ensures the PostgreSQL service is running before attempting to connect. |
| **4. Create database** | Prompts for connection credentials, then creates the `autocreat` database (or a custom name you choose). Skips creation if the database already exists. |
| **5. Create `.env`** | Generates a `.env` file with **random JWT secrets**, your database URL, and sensible defaults. If `.env` already exists, writes to `.env.new` instead. |
| **6. Download Go modules** | Runs `go mod download && go mod verify` to fetch all Go dependencies. |
| **7. Build binary** | Compiles `./cmd/server` into `./bin/server` (or `./bin/server.exe` on Windows) with optimised flags (`-ldflags="-s -w"`). |

**The install script is idempotent** — you can re-run it safely. Already-installed tools are detected and skipped.

---

## Environment Configuration (`.env`)

The `.env` file lives in the `server/` directory. The server reads it automatically on startup via [godotenv](https://github.com/joho/godotenv).

```dotenv
# ── Database ──────────────────────────────────────────────────────────────────
# Full PostgreSQL DSN. Adjust host/port/credentials as needed.
DATABASE_URL=postgres://postgres:password@localhost:5432/autocreat?sslmode=disable

# ── JWT Authentication ─────────────────────────────────────────────────────────
# Keep these secret. Use different values in production.
JWT_SECRET=<random-64-hex-chars>
JWT_REFRESH_SECRET=<random-64-hex-chars>
ACCESS_TOKEN_TTL=15m       # how long access tokens are valid
REFRESH_TOKEN_TTL=168h     # how long refresh tokens are valid (7 days)

# ── Server ────────────────────────────────────────────────────────────────────
PORT=8081
ENV=development            # set to "production" to disable debug output

# ── CORS ──────────────────────────────────────────────────────────────────────
# Comma-separated list of origins allowed to call the API.
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8081

# ── Rate Limiting ──────────────────────────────────────────────────────────────
RATE_LIMIT=100             # requests per second (sustained)
RATE_LIMIT_BURST=200       # maximum burst size

# ── DB Connection Pool ────────────────────────────────────────────────────────
DB_MAX_IDLE_CONNS=10
DB_MAX_OPEN_CONNS=100
DB_CONN_MAX_LIFETIME=1h

# ── Redis (optional) ──────────────────────────────────────────────────────────
# Comment out or leave unset to disable caching entirely.
# REDIS_URL=redis://localhost:6379

# ── Demo Data ─────────────────────────────────────────────────────────────────
# Set to "true" on first run to seed sample data, then remove or set to "false".
# SEED_DB=true
```

### Important security notes

- **Never commit `.env` to version control.** It is listed in `.gitignore`.
- Regenerate `JWT_SECRET` and `JWT_REFRESH_SECRET` in production — the install script generates fresh random values automatically.
- Use `sslmode=require` in `DATABASE_URL` for production deployments.

---

## Server Management Commands

All three platform scripts (`server-linux.sh`, `server-mac.sh`, `server-windows.ps1`) support the same set of commands.

### `start`

Builds the binary if needed (or if any `.go` source file is newer than the binary), then launches the server as a **background process**. A PID file is written to `tmp/server.pid` and all output goes to `tmp/server.log`.

```bash
# Linux / macOS
./scripts/server-linux.sh start
./scripts/server-mac.sh start

# Windows
.\scripts\server-windows.ps1 start
```

### `stop`

Sends `SIGTERM` (Linux/macOS) or `CloseMainWindow` (Windows) to the server for a **graceful shutdown** — in-flight requests finish before the process exits. Falls back to `SIGKILL` / `Kill()` if the server does not exit within 10 seconds.

```bash
./scripts/server-linux.sh stop
.\scripts\server-windows.ps1 stop
```

### `restart`

Equivalent to `stop` followed by `start`.

```bash
./scripts/server-linux.sh restart
```

### `status`

Shows whether the server is running, its PID, port, and the result of a live `/health` check.

```bash
./scripts/server-linux.sh status
```

Example output:
```
✓ Server is RUNNING (PID 12345, port 8081)

  Uptime:  00:42:17
  Log:     /path/to/server/tmp/server.log
  Health:  {"status":"ok","service":"autocreat","version":"1.0.0"}
```

### `logs`

Prints the last 100 lines of the server log.

```bash
# Print last 100 lines
./scripts/server-linux.sh logs

# Follow in real time (Ctrl+C to stop)
./scripts/server-linux.sh logs -f
.\scripts\server-windows.ps1 logs -f
```

### `build`

Compiles the binary without starting the server. Useful to pre-build before a restart.

```bash
./scripts/server-linux.sh build
.\scripts\server-windows.ps1 build
```

---

## Running Migrations

**Migrations run automatically every time the server starts.** No manual step is required.

The migration file is at `migrations/001_init.sql`. It is idempotent — all `CREATE TABLE`, `CREATE INDEX`, and `CREATE EXTENSION` statements use `IF NOT EXISTS`, so re-running is safe.

The migration process:
1. GORM `AutoMigrate` ensures column-level changes (new columns, type changes).
2. The embedded SQL file runs next to create indexes, foreign keys, and PostgreSQL extensions (`uuid-ossp`, `pgcrypto`).

If you need to reset the database during development:

```bash
# Drop and recreate (Linux/macOS)
psql -U postgres -c "DROP DATABASE autocreat;"
psql -U postgres -c "CREATE DATABASE autocreat;"
# Then start the server — migrations will re-run

# Windows (PowerShell)
$env:PGPASSWORD = 'yourpassword'
psql -U postgres -c "DROP DATABASE autocreat;"
psql -U postgres -c "CREATE DATABASE autocreat;"
```

---

## Seeding Demo Data

**Seeding is automatic in development mode.** When `ENV=development` (the default), the server seeds demo data on startup if it has not already done so. No manual step is needed.

The seed is idempotent — it only runs once (checks for the canonical seed company by UUID). Restarting the server does not duplicate data.

Demo credentials created by the seeder:

| Email | Password | Role |
|-------|----------|------|
| `admin@horizondigital.com` | `Demo123!` | Owner |
| `marcus@horizondigital.com` | `Demo123!` | Operations Manager |
| `sofia@horizondigital.com` | `Demo123!` | Support Agent |
| `james@horizondigital.com` | `Demo123!` | Developer |
| `emily@horizondigital.com` | `Demo123!` | Support Agent |
| `demo@autocreat.io` | `Demo123!` | Owner (demo bypass) |

### Disabling or forcing the seed

| Scenario | Setting |
|----------|---------|
| Suppress seeding in development | `SEED_DB=false` in `.env` |
| Force seeding in production / staging | `SEED_DB=true` in `.env` |
| Default (auto-seed in dev, skip in prod) | Leave `SEED_DB` unset |

---

## Troubleshooting

### Server fails to start — "address already in use"

Another process is using the port. Find and stop it:

```bash
# Linux / macOS
lsof -i :<PORT>          # e.g. lsof -i :8081
kill <PID>

# Windows (PowerShell)
netstat -ano | findstr :<PORT>
Stop-Process -Id <PID> -Force
```

Or change `PORT=` in `.env` to an unused port and restart.

---

### `psql: command not found` after install

The PostgreSQL binaries may not be in `$PATH`. Add them manually:

```bash
# Linux (Debian/Ubuntu, PostgreSQL 16)
export PATH="/usr/lib/postgresql/16/bin:$PATH"

# macOS (Homebrew)
export PATH="$(brew --prefix postgresql@16)/bin:$PATH"
```

Add the line to your `~/.bashrc` or `~/.zshrc` to make it permanent.

---

### `go: command not found` after install

The Go binary is at `/usr/local/go/bin/go` (Linux) or managed by Homebrew (macOS). Add to PATH:

```bash
# Linux
export PATH=$PATH:/usr/local/go/bin

# macOS (Apple Silicon)
eval "$(/opt/homebrew/bin/brew shellenv)"
```

---

### Go install fails on Linux behind a proxy

Export proxy settings before running the install script:

```bash
export https_proxy=http://proxy.example.com:8080
export http_proxy=http://proxy.example.com:8080
export no_proxy=localhost,127.0.0.1
./scripts/install-linux.sh
```

---

### "duplicate key value violates unique constraint" on login after register

This is a fixed bug — ensure you have the latest code. The root cause was non-unique JWT refresh tokens when login and register happened within the same second. The fix adds a unique `jti` (JWT ID) claim to every refresh token.

---

### Windows: "running scripts is disabled on this system"

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Run this once per user account. It allows locally-written scripts to run while still requiring signatures for scripts downloaded from the internet.

---

### Logs show database connection errors at startup

Check that PostgreSQL is running and the `DATABASE_URL` in `.env` is correct:

```bash
# Linux / macOS
pg_isready -h localhost -p 5432

# Test the connection string directly
psql "postgres://postgres:password@localhost:5432/autocreat?sslmode=disable" -c '\l'
```

---

### How to check the server is healthy

```bash
curl http://localhost:8081/health
# Expected: {"status":"ok","service":"autocreat","version":"1.0.0"}
```

---

## File Layout (after install)

```
server/
├── bin/
│   └── server          # compiled binary (server.exe on Windows)
├── cmd/
│   └── server/
│       └── main.go     # entry point
├── internal/           # application packages
├── migrations/
│   └── 001_init.sql    # database schema
├── scripts/
│   ├── install-linux.sh
│   ├── install-mac.sh
│   ├── install-windows.ps1
│   ├── server-linux.sh
│   ├── server-mac.sh
│   └── server-windows.ps1
├── tmp/
│   ├── server.pid      # PID of the running server
│   └── server.log      # server stdout/stderr
├── .env                # local config (not committed)
└── SETUP.md            # this file
```
