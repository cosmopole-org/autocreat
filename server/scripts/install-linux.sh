#!/usr/bin/env bash
# AutoCreat Server — Linux Installation Script
# Supports: Ubuntu/Debian, Fedora, RHEL/CentOS/AlmaLinux/Rocky, Arch/Manjaro
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

GO_VERSION="1.23.5"
GO_MIN_MAJOR=1
GO_MIN_MINOR=23

# ── Helpers ──────────────────────────────────────────────────────────────────

detect_distro() {
  [ -f /etc/os-release ] && . /etc/os-release || { DISTRO="unknown"; return; }
  DISTRO="${ID:-unknown}"
  DISTRO_LIKE="${ID_LIKE:-}"
}

has_cmd() { command -v "$1" &>/dev/null; }

go_ok() {
  has_cmd go || return 1
  local ver; ver=$(go version 2>/dev/null | grep -oP 'go\K[0-9]+\.[0-9]+' || echo "0.0")
  local major minor
  major=$(echo "$ver" | cut -d. -f1)
  minor=$(echo "$ver" | cut -d. -f2)
  [ "$major" -gt "$GO_MIN_MAJOR" ] || \
    { [ "$major" -eq "$GO_MIN_MAJOR" ] && [ "$minor" -ge "$GO_MIN_MINOR" ]; }
}

generate_secret() {
  if has_cmd openssl; then openssl rand -hex 32
  else cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1
  fi
}

# ── Step 1: Install Go ───────────────────────────────────────────────────────

install_go() {
  if go_ok; then
    ok "Go $(go version | grep -oP 'go\K[0-9.]+') already installed (>= ${GO_MIN_MAJOR}.${GO_MIN_MINOR})"
    return
  fi

  step "Installing Go ${GO_VERSION}"

  local arch
  case "$(uname -m)" in
    x86_64)  arch="amd64"  ;;
    aarch64) arch="arm64"  ;;
    armv7l)  arch="armv6l" ;;
    *) die "Unsupported CPU architecture: $(uname -m)" ;;
  esac

  local tarball="go${GO_VERSION}.linux-${arch}.tar.gz"
  local url="https://go.dev/dl/${tarball}"
  local tmp; tmp=$(mktemp -d)

  echo "  Downloading ${url}..."
  curl -fsSL --progress-bar "$url" -o "${tmp}/${tarball}"

  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "${tmp}/${tarball}"
  rm -rf "$tmp"

  # Persist to shell profile
  export PATH=$PATH:/usr/local/go/bin
  export GOPATH="$HOME/go"
  for profile in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    [ -f "$profile" ] || continue
    grep -q '/usr/local/go/bin' "$profile" && continue
    {
      echo ''
      echo '# Go'
      echo 'export PATH=$PATH:/usr/local/go/bin'
      echo 'export GOPATH=$HOME/go'
      echo 'export PATH=$PATH:$GOPATH/bin'
    } >> "$profile"
    ok "Added Go paths to ${profile}"
    break
  done

  go_ok || die "Go installation failed — go binary not found in PATH"
  ok "Go ${GO_VERSION} installed"
}

# ── Step 2: Install PostgreSQL ───────────────────────────────────────────────

install_postgresql() {
  if has_cmd psql; then
    ok "PostgreSQL client already installed"
    return
  fi

  step "Installing PostgreSQL"

  case "$DISTRO" in
    ubuntu|debian|linuxmint|pop|elementary)
      sudo apt-get update -qq
      sudo apt-get install -y postgresql postgresql-client
      ;;
    fedora)
      sudo dnf install -y postgresql-server postgresql
      sudo postgresql-setup --initdb 2>/dev/null || true
      sudo systemctl enable --now postgresql
      ;;
    rhel|centos|almalinux|rocky|ol)
      sudo dnf install -y \
        "https://download.postgresql.org/pub/repos/yum/reporpms/EL-$(rpm -E %{rhel})-x86_64/pgdg-redhat-repo-latest.noarch.rpm" \
        2>/dev/null || true
      sudo dnf module disable -y postgresql 2>/dev/null || true
      sudo dnf install -y postgresql16-server postgresql16
      sudo /usr/pgsql-16/bin/postgresql-16-setup initdb 2>/dev/null || true
      sudo systemctl enable --now postgresql-16
      ;;
    arch|manjaro|endeavouros)
      sudo pacman -S --noconfirm postgresql
      sudo -u postgres initdb -D /var/lib/postgres/data 2>/dev/null || true
      sudo systemctl enable --now postgresql
      ;;
    opensuse*|sles)
      sudo zypper install -y postgresql postgresql-server
      sudo systemctl enable --now postgresql
      ;;
    *)
      warn "Unknown distro '${DISTRO}'. Attempting apt-get..."
      sudo apt-get update -qq && sudo apt-get install -y postgresql postgresql-client \
        || die "Could not install PostgreSQL. Install it manually then re-run."
      ;;
  esac

  ok "PostgreSQL installed"
}

# ── Step 3: Ensure PostgreSQL is running ─────────────────────────────────────

start_postgresql() {
  step "Checking PostgreSQL service"

  if pg_isready -q 2>/dev/null; then
    ok "PostgreSQL is already running"
    return
  fi

  for svc in postgresql postgresql-16 postgresql-15 postgresql-14; do
    sudo systemctl start "$svc" 2>/dev/null && {
      ok "PostgreSQL started (${svc})"
      return
    }
  done

  # pg_ctlcluster fallback (Debian/Ubuntu)
  if has_cmd pg_ctlcluster; then
    local ver; ver=$(pg_lsclusters -h | awk 'NR==1{print $1}')
    sudo pg_ctlcluster "$ver" main start 2>/dev/null || true
  fi

  pg_isready -q 2>/dev/null || warn "PostgreSQL may not be running. Check manually: sudo systemctl status postgresql"
}

# ── Step 4: Database setup ───────────────────────────────────────────────────

setup_database() {
  step "Configuring PostgreSQL database"

  echo ""
  echo "  Enter your PostgreSQL connection details."
  echo "  Press Enter to accept defaults shown in brackets."
  echo ""

  read -r -p "  Host     [localhost]: " DB_HOST;  DB_HOST="${DB_HOST:-localhost}"
  read -r -p "  Port     [5432]:      " DB_PORT;  DB_PORT="${DB_PORT:-5432}"
  read -r -p "  Admin user [postgres]: " DB_USER; DB_USER="${DB_USER:-postgres}"
  read -r -s -p "  Admin password:       " DB_PASS; echo ""
  read -r -p "  Database name [autocreat]: " DB_NAME; DB_NAME="${DB_NAME:-autocreat}"

  # Test connection
  PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -c '\q' 2>/dev/null \
    || die "Cannot connect to PostgreSQL at ${DB_HOST}:${DB_PORT} as '${DB_USER}'. Check credentials."
  ok "Connected to PostgreSQL"

  # Create main database if missing
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

  # Create test database if missing (used by go test ./...)
  local test_db="${DB_NAME}_test"
  local test_exists
  test_exists=$(PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
    -tAc "SELECT 1 FROM pg_database WHERE datname='${test_db}'" 2>/dev/null || echo "")
  if [ "$test_exists" = "1" ]; then
    ok "Test database '${test_db}' already exists"
  else
    PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
      -c "CREATE DATABASE \"${test_db}\";" \
      || die "Failed to create test database '${test_db}'"
    ok "Test database '${test_db}' created"
  fi

  # Export for .env creation
  export CFG_DATABASE_URL="postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=disable"
  export CFG_PORT
  read -r -p "  Server port [8081]: " CFG_PORT; CFG_PORT="${CFG_PORT:-8081}"
}

# ── Step 5: Create .env ──────────────────────────────────────────────────────

create_env() {
  step "Creating .env file"

  local env_file="${SERVER_DIR}/.env"

  if [ -f "$env_file" ]; then
    warn ".env already exists — writing to .env.new instead. Review and rename it."
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

# ── Demo data ─────────────────────────────────────────────────
# Seeding runs automatically when ENV=development (the default).
# Set SEED_DB=false to suppress it, or SEED_DB=true to force it
# in any environment.
# SEED_DB=false
ENVEOF

  ok ".env written to ${env_file}"
}

# ── Step 6: Download Go modules ──────────────────────────────────────────────

download_deps() {
  step "Downloading Go module dependencies"
  (cd "$SERVER_DIR" && go mod download && go mod verify)
  ok "Dependencies ready"
}

# ── Step 7: Build binary ─────────────────────────────────────────────────────

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
  echo "  Start server:   ./scripts/server-linux.sh start"
  echo "  Stop server:    ./scripts/server-linux.sh stop"
  echo "  View logs:      ./scripts/server-linux.sh logs"
  echo ""
  echo "  Database migrations run automatically on first start."
  echo ""
}

# ── Entrypoint ───────────────────────────────────────────────────────────────

echo -e "${BLUE}${BOLD}"
echo "══════════════════════════════════════════"
echo "  AutoCreat Server — Linux Setup"
echo "══════════════════════════════════════════${NC}"

detect_distro
install_go
install_postgresql
start_postgresql
setup_database
create_env
download_deps
build_binary
summary
