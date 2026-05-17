#!/usr/bin/env bash
# AutoCreat Server — macOS Installation Script
# Requires macOS 12 Monterey or later. Uses Homebrew.
set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

step()  { echo -e "\n${BLUE}${BOLD}▶ $*${NC}"; }
ok()    { echo -e "  ${GREEN}✓ $*${NC}"; }
warn()  { echo -e "  ${YELLOW}⚠ $*${NC}"; }
die()   { echo -e "\n${RED}✗ ERROR: $*${NC}" >&2; exit 1; }

# ── Paths ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(dirname "$SCRIPT_DIR")"

GO_MIN_MAJOR=1
GO_MIN_MINOR=23

# ── Helpers ──────────────────────────────────────────────────────────────────

has_cmd() { command -v "$1" &>/dev/null; }

go_ok() {
  has_cmd go || return 1
  local ver; ver=$(go version 2>/dev/null | grep -oE 'go[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+' || echo "0.0")
  local major minor
  major=$(echo "$ver" | cut -d. -f1)
  minor=$(echo "$ver" | cut -d. -f2)
  [ "$major" -gt "$GO_MIN_MAJOR" ] || \
    { [ "$major" -eq "$GO_MIN_MAJOR" ] && [ "$minor" -ge "$GO_MIN_MINOR" ]; }
}

generate_secret() {
  if has_cmd openssl; then openssl rand -hex 32
  else LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 64 | head -n 1
  fi
}

# ── Step 1: Homebrew ─────────────────────────────────────────────────────────

install_homebrew() {
  if has_cmd brew; then
    ok "Homebrew already installed ($(brew --version | head -1))"
    return
  fi

  step "Installing Homebrew"
  echo "  The Homebrew installer will prompt for your macOS password."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH for Apple Silicon
  if [ "$(uname -m)" = "arm64" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    for profile in "$HOME/.zprofile" "$HOME/.bash_profile"; do
      [ -f "$profile" ] || continue
      grep -q 'homebrew' "$profile" && break
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$profile"
      ok "Added Homebrew to ${profile}"
      break
    done
  fi

  has_cmd brew || die "Homebrew installation failed"
  ok "Homebrew installed"
}

# ── Step 2: Install Go ───────────────────────────────────────────────────────

install_go() {
  if go_ok; then
    ok "Go $(go version | grep -oE 'go[0-9.]+' | head -1) already installed (>= ${GO_MIN_MAJOR}.${GO_MIN_MINOR})"
    return
  fi

  step "Installing Go via Homebrew"
  brew install go
  # Reload PATH in case brew shims changed
  eval "$(brew shellenv 2>/dev/null || true)"

  go_ok || die "Go installation failed. Try: brew link --overwrite go"
  ok "Go installed: $(go version)"
}

# ── Step 3: Install PostgreSQL ───────────────────────────────────────────────

install_postgresql() {
  if has_cmd psql; then
    ok "PostgreSQL client already installed"
    return
  fi

  step "Installing PostgreSQL via Homebrew"
  brew install postgresql@16

  # Ensure psql is on PATH
  local pg_bin
  pg_bin="$(brew --prefix)/opt/postgresql@16/bin"
  export PATH="${pg_bin}:$PATH"

  for profile in "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.bash_profile" "$HOME/.bashrc"; do
    [ -f "$profile" ] || continue
    grep -q 'postgresql@16' "$profile" && break
    echo "export PATH=\"${pg_bin}:\$PATH\"" >> "$profile"
    ok "Added PostgreSQL to PATH in ${profile}"
    break
  done

  ok "PostgreSQL installed"
}

# ── Step 4: Start PostgreSQL service ─────────────────────────────────────────

start_postgresql() {
  step "Starting PostgreSQL service"

  if pg_isready -q 2>/dev/null; then
    ok "PostgreSQL is already running"
    return
  fi

  # Try brew services (preferred)
  if has_cmd brew; then
    brew services start postgresql@16 2>/dev/null \
      || brew services start postgresql 2>/dev/null \
      || true
    sleep 2
  fi

  if pg_isready -q 2>/dev/null; then
    ok "PostgreSQL started"
  else
    warn "PostgreSQL may not have started. Try: brew services start postgresql@16"
    warn "Then re-run this script."
    exit 1
  fi
}

# ── Step 5: Database setup ───────────────────────────────────────────────────

setup_database() {
  step "Configuring PostgreSQL database"

  echo ""
  echo "  Enter your PostgreSQL connection details."
  echo "  Press Enter to accept defaults shown in brackets."
  echo ""

  read -r -p "  Host     [localhost]: " DB_HOST;  DB_HOST="${DB_HOST:-localhost}"
  read -r -p "  Port     [5432]:      " DB_PORT;  DB_PORT="${DB_PORT:-5432}"
  read -r -p "  Admin user [postgres]: " DB_USER; DB_USER="${DB_USER:-postgres}"
  read -r -s -p "  Admin password (leave blank if using peer auth): " DB_PASS; echo ""
  read -r -p "  Database name [autocreat]: " DB_NAME; DB_NAME="${DB_NAME:-autocreat}"

  # Test connection
  PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -c '\q' 2>/dev/null \
    || die "Cannot connect to PostgreSQL at ${DB_HOST}:${DB_PORT} as '${DB_USER}'.\nOn macOS the default superuser is your macOS username, not 'postgres'.\nTry: psql -c '\\l' to find your username."
  ok "Connected to PostgreSQL"

  # Create database
  local exists
  exists=$(PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
    -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" 2>/dev/null || echo "")
  if [ "$exists" = "1" ]; then
    ok "Database '${DB_NAME}' already exists"
  else
    PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
      -c "CREATE DATABASE \"${DB_NAME}\";" \
      || die "Failed to create database '${DB_NAME}'"
    ok "Database '${DB_NAME}' created"
  fi

  export CFG_DATABASE_URL="postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=disable"
  read -r -p "  Server port [8081]: " CFG_PORT; CFG_PORT="${CFG_PORT:-8081}"
}

# ── Step 6: Create .env ──────────────────────────────────────────────────────

create_env() {
  step "Creating .env file"

  local env_file="${SERVER_DIR}/.env"
  if [ -f "$env_file" ]; then
    warn ".env already exists — writing to .env.new. Review and rename it."
    env_file="${SERVER_DIR}/.env.new"
  fi

  cat > "$env_file" << ENVEOF
# ── Database ─────────────────────────────────────────────────
DATABASE_URL=${CFG_DATABASE_URL}

# ── JWT Authentication ────────────────────────────────────────
JWT_SECRET=$(generate_secret)
JWT_REFRESH_SECRET=$(generate_secret)
ACCESS_TOKEN_TTL=15m
REFRESH_TOKEN_TTL=168h

# ── Server ────────────────────────────────────────────────────
PORT=${CFG_PORT}
ENV=development

# ── CORS (comma-separated list of allowed origins) ────────────
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:${CFG_PORT}

# ── Rate Limiting ─────────────────────────────────────────────
RATE_LIMIT=100
RATE_LIMIT_BURST=200

# ── DB Connection Pool ────────────────────────────────────────
DB_MAX_IDLE_CONNS=10
DB_MAX_OPEN_CONNS=100
DB_CONN_MAX_LIFETIME=1h

# ── Redis (optional — comment out to disable caching) ─────────
# REDIS_URL=redis://localhost:6379

# ── Demo data (set to "true" once to seed, then remove) ───────
# SEED_DB=true
ENVEOF

  ok ".env written to ${env_file}"
}

# ── Step 7: Download Go modules ──────────────────────────────────────────────

download_deps() {
  step "Downloading Go module dependencies"
  (cd "$SERVER_DIR" && go mod download && go mod verify)
  ok "Dependencies ready"
}

# ── Step 8: Build binary ─────────────────────────────────────────────────────

build_binary() {
  step "Building server binary"
  mkdir -p "${SERVER_DIR}/bin"
  (cd "$SERVER_DIR" && CGO_ENABLED=0 go build -ldflags="-s -w" -o bin/server ./cmd/server)
  ok "Binary built: ${SERVER_DIR}/bin/server"
}

# ── Done ─────────────────────────────────────────────────────────────────────

summary() {
  echo ""
  echo -e "${GREEN}${BOLD}══════════════════════════════════════════"
  echo -e "  Installation complete!"
  echo -e "══════════════════════════════════════════${NC}"
  echo ""
  echo "  Review config:  ${SERVER_DIR}/.env"
  echo ""
  echo "  Start server:   ./scripts/server-mac.sh start"
  echo "  Stop server:    ./scripts/server-mac.sh stop"
  echo "  View logs:      ./scripts/server-mac.sh logs"
  echo ""
  echo "  Database migrations run automatically on first start."
  echo ""
}

# ── Entrypoint ───────────────────────────────────────────────────────────────

echo -e "${BLUE}${BOLD}"
echo "══════════════════════════════════════════"
echo "  AutoCreat Server — macOS Setup"
echo "══════════════════════════════════════════${NC}"

install_homebrew
install_go
install_postgresql
start_postgresql
setup_database
create_env
download_deps
build_binary
summary
