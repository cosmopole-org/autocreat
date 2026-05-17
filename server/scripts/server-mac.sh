#!/usr/bin/env bash
# AutoCreat Server — macOS Process Manager
# Usage: ./scripts/server-mac.sh {start|stop|restart|status|logs|build}
set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

info()  { echo -e "${BLUE}${BOLD}▶ $*${NC}"; }
ok()    { echo -e "${GREEN}✓ $*${NC}"; }
warn()  { echo -e "${YELLOW}⚠ $*${NC}"; }
die()   { echo -e "${RED}✗ $*${NC}" >&2; exit 1; }

# ── Paths ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(dirname "$SCRIPT_DIR")"
BIN="${SERVER_DIR}/bin/server"
PID_FILE="${SERVER_DIR}/tmp/server.pid"
LOG_FILE="${SERVER_DIR}/tmp/server.log"
ENV_FILE="${SERVER_DIR}/.env"

mkdir -p "${SERVER_DIR}/tmp"

# ── Helpers ──────────────────────────────────────────────────────────────────

is_running() {
  [ -f "$PID_FILE" ] || return 1
  local pid; pid=$(cat "$PID_FILE")
  [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

get_pid() {
  [ -f "$PID_FILE" ] && cat "$PID_FILE" || echo ""
}

stale_pid() {
  [ -f "$PID_FILE" ] && ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

check_env() {
  [ -f "$ENV_FILE" ] || die ".env not found at ${ENV_FILE}\nRun ./scripts/install-mac.sh first."
}

check_go() {
  command -v go &>/dev/null && return

  # Try Homebrew Go locations
  for p in \
    "$(brew --prefix go 2>/dev/null)/bin" \
    "/opt/homebrew/bin" \
    "/usr/local/bin" \
    "$HOME/go/bin"; do
    [ -x "${p}/go" ] && { export PATH="${p}:$PATH"; return; }
  done

  die "Go not found. Run ./scripts/install-mac.sh first."
}

uptime_for_pid() {
  # macOS ps uses -o etime= differently; lstart gives absolute start time
  ps -p "$1" -o lstart= 2>/dev/null | tr -d '\n' || echo "unknown"
}

# ── Build ────────────────────────────────────────────────────────────────────

cmd_build() {
  info "Building server binary"
  check_go
  check_env
  mkdir -p "${SERVER_DIR}/bin"
  (cd "$SERVER_DIR" && CGO_ENABLED=0 go build -ldflags="-s -w" -o bin/server ./cmd/server)
  ok "Built: ${BIN}"
}

# ── Start ────────────────────────────────────────────────────────────────────

cmd_start() {
  check_env

  if is_running; then
    ok "Server is already running (PID $(get_pid))"
    return
  fi

  stale_pid && { warn "Removing stale PID file"; rm -f "$PID_FILE"; }

  check_go

  # Build if binary missing or any .go file is newer than binary
  if [ ! -f "$BIN" ] || [ -n "$(find "${SERVER_DIR}" -name '*.go' -newer "$BIN" 2>/dev/null | head -1)" ]; then
    info "Binary outdated or missing — building first..."
    cmd_build
  fi

  info "Starting AutoCreat server"

  # Use nohup to detach from terminal
  nohup "$BIN" >> "$LOG_FILE" 2>&1 &
  local pid=$!
  echo "$pid" > "$PID_FILE"

  sleep 1
  if ! is_running; then
    rm -f "$PID_FILE"
    die "Server failed to start. Check logs: ${LOG_FILE}\n$(tail -20 "$LOG_FILE" 2>/dev/null)"
  fi

  local port; port=$(grep -E '^PORT=' "$ENV_FILE" 2>/dev/null | cut -d= -f2 | tr -d ' ' || echo "8081")

  ok "Server started (PID ${pid})"
  echo "  Listening on http://localhost:${port}"
  echo "  Log file:    ${LOG_FILE}"
  echo "  PID file:    ${PID_FILE}"
}

# ── Stop ─────────────────────────────────────────────────────────────────────

cmd_stop() {
  if ! is_running; then
    stale_pid && rm -f "$PID_FILE"
    warn "Server is not running"
    return
  fi

  local pid; pid=$(get_pid)
  info "Stopping server (PID ${pid})"

  kill -TERM "$pid" 2>/dev/null || true

  local waited=0
  while kill -0 "$pid" 2>/dev/null && [ $waited -lt 10 ]; do
    sleep 1
    waited=$((waited+1))
  done

  if kill -0 "$pid" 2>/dev/null; then
    warn "Server did not stop gracefully — sending SIGKILL"
    kill -KILL "$pid" 2>/dev/null || true
    sleep 1
  fi

  rm -f "$PID_FILE"
  ok "Server stopped"
}

# ── Restart ──────────────────────────────────────────────────────────────────

cmd_restart() {
  info "Restarting server"
  cmd_stop
  sleep 1
  cmd_start
}

# ── Status ───────────────────────────────────────────────────────────────────

cmd_status() {
  if is_running; then
    local pid; pid=$(get_pid)
    local port; port=$(grep -E '^PORT=' "$ENV_FILE" 2>/dev/null | cut -d= -f2 | tr -d ' ' || echo "?")
    ok "Server is RUNNING (PID ${pid}, port ${port})"
    echo ""
    echo "  Started: $(uptime_for_pid "$pid")"
    echo "  Log:     ${LOG_FILE}"

    if command -v curl &>/dev/null; then
      local health; health=$(NO_PROXY=localhost,127.0.0.1 curl -s --noproxy '*' \
        "http://localhost:${port}/health" --max-time 2 2>/dev/null || echo "unreachable")
      echo "  Health:  ${health}"
    fi
  else
    stale_pid && rm -f "$PID_FILE"
    echo -e "${YELLOW}● Server is STOPPED${NC}"
  fi
}

# ── Logs ─────────────────────────────────────────────────────────────────────

cmd_logs() {
  [ -f "$LOG_FILE" ] || die "No log file found at ${LOG_FILE}"
  echo "── ${LOG_FILE} ──────────"
  if [ "${1:-}" = "-f" ] || [ "${1:-}" = "--follow" ]; then
    tail -f "$LOG_FILE"
  else
    tail -100 "$LOG_FILE"
  fi
}

# ── Help ─────────────────────────────────────────────────────────────────────

cmd_help() {
  echo ""
  echo -e "${BOLD}AutoCreat Server Manager — macOS${NC}"
  echo ""
  echo "  Usage: $0 <command> [options]"
  echo ""
  echo "  Commands:"
  echo "    start       Build (if needed) and start the server in the background"
  echo "    stop        Gracefully stop the running server"
  echo "    restart     Stop then start"
  echo "    status      Show running status and health"
  echo "    logs        Print last 100 log lines"
  echo "    logs -f     Follow log output in real time"
  echo "    build       Compile the server binary without starting"
  echo "    help        Show this help"
  echo ""
}

# ── Dispatch ─────────────────────────────────────────────────────────────────

case "${1:-help}" in
  start)   cmd_start   ;;
  stop)    cmd_stop    ;;
  restart) cmd_restart ;;
  status)  cmd_status  ;;
  logs)    cmd_logs "${2:-}" ;;
  build)   cmd_build   ;;
  help|--help|-h) cmd_help ;;
  *) die "Unknown command: $1\nRun $0 help" ;;
esac
