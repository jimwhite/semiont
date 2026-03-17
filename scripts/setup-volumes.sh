#!/usr/bin/env bash
# scripts/setup-volumes.sh
#
# One-time setup before opening the Semiont Mac dev container.
#
# Named Docker volumes (postgres_data, neo4j_data, neo4j_logs,
# node_modules, semiont_project) are created automatically by
# `docker compose up` when VS Code builds the dev container.
# This script only handles things that Compose cannot do:
#
#   • Verifying that Docker Desktop is running
#   • Copying .devcontainer/mac/.env from the template
#
# Run once before opening VS Code:
#   bash scripts/setup-volumes.sh

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

echo ""
echo "========================================"
echo "  Semiont Mac Dev Setup"
echo "========================================"
echo ""

# ── Pre-flight: Docker must be running ────────────────────────────────────
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

# ── .env bootstrap ────────────────────────────────────────────────────────
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${REPO_ROOT}/.devcontainer/mac/.env"
ENV_EXAMPLE="${REPO_ROOT}/.devcontainer/mac/.env.example"

info "Checking .env file..."

if [ -f "$ENV_FILE" ]; then
  success ".devcontainer/mac/.env already exists – skipping (edit manually if needed)"
else
  if [ -f "$ENV_EXAMPLE" ]; then
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    success "Created .devcontainer/mac/.env from .env.example"
    warn "Edit .devcontainer/mac/.env before continuing:"
    echo "     • Set INFERENCE_TYPE=ollama or lmstudio"
    echo "     • Confirm LLM_HOST (change if your LLM server is on a different machine)"
    echo "     • Confirm OLLAMA_MODEL / LMSTUDIO_MODEL matches what you have loaded"
  else
    warn ".env.example not found – create .devcontainer/mac/.env manually"
  fi
fi

# ── Summary ────────────────────────────────────────────────────────────────
echo ""
echo "========================================"
echo "  Ready!"
echo "========================================"
echo ""
echo "Next steps:"
echo ""
echo "  1. Edit .devcontainer/mac/.env (if you haven't already)"
echo "     • INFERENCE_TYPE=ollama  (or lmstudio / anthropic)"
echo "     • LLM_HOST=host.docker.internal  (or a specific IP on VPN)"
echo ""
echo "  2. Make sure your chosen LLM is running:"
echo "     • Ollama:    ollama serve  &&  ollama pull <model>"
echo "     • LM Studio: Developer tab → Start Server (port 1234)"
echo ""
echo "  3. Open the repository in VS Code and reopen in container:"
echo "     code ${REPO_ROOT}"
echo "     → F1 → 'Dev Containers: Reopen in Container'"
echo "     → Select 'Semiont Development (Mac)'"
echo ""
echo "     Docker Compose will automatically create all required volumes"
echo "     (postgres_data, neo4j_data, neo4j_logs, node_modules, semiont_project)"
echo "     and start PostgreSQL 18 and Neo4j 5 alongside the dev container."
echo ""
echo "  4. After the container builds, start services:"
echo "     semiont start"
echo ""
echo "  5. Open http://localhost:8080 in your browser."
echo "     Neo4j Browser: http://localhost:7474"
echo ""
