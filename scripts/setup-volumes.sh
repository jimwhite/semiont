#!/usr/bin/env bash
# setup-volumes.sh
#
# Creates the Docker volumes and local directories required by the
# Semiont Mac dev environment before starting the dev container for
# the first time.
#
# Run this once on your Mac host before opening VS Code:
#   bash scripts/setup-volumes.sh
#
# It is safe to run multiple times – existing volumes and directories
# are left untouched.

set -euo pipefail

# ── Colors ─────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${BLUE}▶${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn()    { echo -e "${YELLOW}⚠${NC} $*"; }
error()   { echo -e "${RED}✗${NC} $*" >&2; }

# ── Pre-flight checks ──────────────────────────────────────────────────────
echo ""
echo "========================================"
echo "  Semiont Mac Volume Setup"
echo "========================================"
echo ""

if ! command -v docker &>/dev/null; then
  error "Docker is not installed or not in PATH."
  echo "  Install Docker Desktop from https://www.docker.com/products/docker-desktop/"
  exit 1
fi

if ! docker info &>/dev/null; then
  error "Docker daemon is not running."
  echo "  Start Docker Desktop and try again."
  exit 1
fi

success "Docker is running ($(docker version --format '{{.Server.Version}}' 2>/dev/null || echo 'unknown version'))"

# ── Docker volumes ─────────────────────────────────────────────────────────
info "Creating Docker volumes..."

create_volume() {
  local name="$1"
  local description="$2"
  if docker volume inspect "$name" &>/dev/null; then
    echo "  Volume '${name}' already exists – skipping"
  else
    docker volume create "$name" >/dev/null
    success "Created volume: ${name} (${description})"
  fi
}

create_volume "semiont_postgres_data"  "PostgreSQL persistent data"
create_volume "semiont_node_modules"   "Node.js dependencies (container-native binaries)"
create_volume "semiont_project"        "Semiont project workspace (credentials, provisioned config)"

# ── Local directories ──────────────────────────────────────────────────────
info "Creating local directories..."

# Resolve the repository root (parent of this script's directory)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

create_dir() {
  local path="$1"
  local description="$2"
  if [ -d "$path" ]; then
    echo "  Directory '${path}' already exists – skipping"
  else
    mkdir -p "$path"
    success "Created directory: ${path} (${description})"
  fi
}

create_dir "${REPO_ROOT}/.devcontainer/mac"       "Mac devcontainer configuration"
create_dir "${REPO_ROOT}/data/uploads"            "File upload storage"
create_dir "${REPO_ROOT}/data/events"             "Event store"
create_dir "${REPO_ROOT}/data/content"            "Content-addressed storage"

# ── .env file ─────────────────────────────────────────────────────────────
ENV_FILE="${REPO_ROOT}/.devcontainer/mac/.env"
ENV_EXAMPLE="${REPO_ROOT}/.devcontainer/mac/.env.example"

if [ -f "$ENV_FILE" ]; then
  echo "  .env already exists – skipping (edit manually if needed)"
else
  if [ -f "$ENV_EXAMPLE" ]; then
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    success "Created .devcontainer/mac/.env from .env.example"
    warn "Edit .devcontainer/mac/.env to set your inference provider (INFERENCE_TYPE=ollama or lmstudio)"
  else
    warn ".env.example not found – create .devcontainer/mac/.env manually"
  fi
fi

# ── Summary ────────────────────────────────────────────────────────────────
echo ""
echo "========================================"
echo "  Setup complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo ""
echo "  1. Edit .devcontainer/mac/.env"
echo "     • Set INFERENCE_TYPE=ollama  (or lmstudio)"
echo "     • Confirm OLLAMA_MODEL / LMSTUDIO_MODEL matches what you have loaded"
echo ""
echo "  2. Make sure your chosen LLM is running on your Mac:"
echo "     • Ollama:    ollama serve  (and: ollama pull <model>)"
echo "     • LM Studio: Developer tab → Start Server (port 1234)"
echo ""
echo "  3. Open the repository in VS Code:"
echo "     code ${REPO_ROOT}"
echo "     → Press F1 → 'Dev Containers: Reopen in Container'"
echo "     → Select 'Semiont Development (Mac)'"
echo ""
echo "  4. After the container builds, start services:"
echo "     semiont start"
echo ""
echo "  5. Open http://localhost:8080 in your browser."
echo ""
