# Semiont Dev Container – Mac (Docker Desktop)

This directory contains a VS Code Dev Container configuration optimized for **macOS with Docker Desktop**, where [Ollama](https://ollama.ai) or [LM Studio](https://lmstudio.ai) is already running natively on the host.

> For GitHub Codespaces or Linux, use the configuration in the parent [`.devcontainer`](..) directory instead.

---

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | ≥ 4.x | Must be running |
| [VS Code](https://code.visualstudio.com) | Latest | |
| [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) | Latest | |
| Ollama **or** LM Studio | Any recent | Running on your Mac (or another machine) |

---

## Quick Start

### 1. Run the setup script (once)

```bash
bash scripts/setup-volumes.sh
```

This checks that Docker is running and copies `.devcontainer/mac/.env.example` → `.devcontainer/mac/.env` for you to edit. Docker Compose will create all required named volumes automatically when the container starts.

### 2. Configure `.devcontainer/mac/.env`

#### LLM host

`LLM_HOST` controls where the backend looks for Ollama or LM Studio:

```dotenv
# Default: Docker Desktop magic hostname → your Mac
LLM_HOST=host.docker.internal

# VPN / remote machine: use its IP instead
# LLM_HOST=192.168.1.100
```

#### Option A – Ollama (default)

```dotenv
INFERENCE_TYPE=ollama
OLLAMA_MODEL=llama3.2       # any model you have pulled
```

Make sure Ollama is running and the model is available:

```bash
ollama serve          # start the server (if not already running)
ollama pull llama3.2  # download the model
```

#### Option B – LM Studio

```dotenv
INFERENCE_TYPE=lmstudio
LMSTUDIO_MODEL=local-model  # copy the model ID from LM Studio
```

In LM Studio:
1. Load a model from the home screen.
2. Go to the **Developer** tab and click **Start Server** (default port 1234).
3. Copy the model identifier shown in the UI and paste it as `LMSTUDIO_MODEL`.

#### Option C – Anthropic (cloud)

```dotenv
INFERENCE_TYPE=anthropic
ANTHROPIC_API_KEY=sk-ant-xxxxx
```

### 3. Open in VS Code Dev Container

```bash
code .   # open the repo in VS Code
```

Then press **F1** → `Dev Containers: Reopen in Container` → select **Semiont Development (Mac)**.

Docker Compose will automatically start alongside the dev container:
- **PostgreSQL 18** on port 5432
- **Neo4j 5** on ports 7474 (Browser) and 7687 (Bolt)

Then `setup.sh` runs to install dependencies, build packages, provision services, and create an admin user.

Estimated first-run time: **5–10 minutes**.

### 4. Copy the environment config for your LLM

Inside the container terminal, swap in the environment file that matches your inference provider:

```bash
# For Ollama:
cp /workspace/.devcontainer/mac/environments-ollama.json \
   /workspace/project/environments/local.json

# For LM Studio:
cp /workspace/.devcontainer/mac/environments-lmstudio.json \
   /workspace/project/environments/local.json
```

Then re-provision the backend:

```bash
semiont provision --service backend --force
```

### 5. Start services

```bash
semiont start
```

Check everything is healthy:

```bash
semiont check
```

Open **<http://localhost:8080>** in your browser.  
Login credentials are saved to `/workspace/credentials.json`.  
Neo4j Browser: **<http://localhost:7474>** (username `neo4j`, password from `NEO4J_LOCAL_PASSWORD` in `.env`).

---

## How host LLM access works

`LLM_HOST` defaults to `host.docker.internal` – the Docker Desktop magic hostname that resolves to your Mac. You can override it with any IP address:

```
┌──────────────────────────────────────────────────┐
│  Mac host (or VPN-reachable machine)             │
│                                                  │
│  Ollama  :11434  ──────────────────┐             │
│  LM Studio :1234/v1  ──────────┐  │             │
│                                 │  │             │
│  ┌──────────────────────────┐   │  │             │
│  │  Docker Desktop          │   │  │             │
│  │                          │   │  │             │
│  │  devcontainer            │   │  │             │
│  │   LLM_HOST=<host>  ──────┼───┴──┘             │
│  │                          │                    │
│  │  postgres  :5432         │                    │
│  │  neo4j     :7687/:7474   │                    │
│  └──────────────────────────┘                    │
└──────────────────────────────────────────────────┘
```

---

## Switching between Ollama and LM Studio

You can switch at any time without rebuilding the container:

```bash
# Inside the container
cp /workspace/.devcontainer/mac/environments-ollama.json \
   /workspace/project/environments/local.json
semiont provision --service backend --force
semiont stop --service backend && semiont start --service backend
```

---

## Common commands (inside the container)

```bash
# Services
semiont start                         # Start all services
semiont stop                          # Stop all services
semiont check                         # Health check

# Re-provision after config changes
semiont provision --service backend --force
semiont provision --service frontend --force

# Database
cd apps/backend
npm run db:push                       # Push Prisma schema changes
npm run db:studio                     # Open Prisma Studio (port 5555)

# Development
npm run test                          # Run all tests
npm run build                         # Build all packages
```

---

## Troubleshooting

### `ECONNREFUSED` connecting to Ollama / LM Studio

- Confirm the service is running (`ollama ps` or check LM Studio Developer tab).
- Verify the port: Ollama defaults to **11434**, LM Studio defaults to **1234**.
- Test from inside the container:
  ```bash
  curl http://${LLM_HOST}:11434/api/tags   # Ollama
  curl http://${LLM_HOST}:1234/v1/models   # LM Studio
  ```
- If on VPN, set `LLM_HOST` in `.env` to the actual IP of the machine running the LLM.

### Neo4j not ready

Neo4j 5 takes ~30 seconds on first start while it initializes the data directory.  
The dev container `depends_on` healthcheck will wait for it automatically.

Check status:
```bash
docker compose -f .devcontainer/mac/docker-compose.yml ps
```

Open the Neo4j Browser at **<http://localhost:7474>** (connect with `bolt://localhost:7687`, username `neo4j`, password from `NEO4J_LOCAL_PASSWORD`).

### Container can't reach PostgreSQL

PostgreSQL and Neo4j run as Docker Compose services. The backend `DATABASE_URL` and Neo4j env vars are already wired to the right internal hostnames (`postgres:5432`, `neo4j:7687`).

```bash
docker compose -f .devcontainer/mac/docker-compose.yml ps
```

### Resetting to a clean state

```bash
# Remove containers and volumes (all local data will be lost)
docker compose -f .devcontainer/mac/docker-compose.yml down -v
# Then reopen the container in VS Code – volumes will be recreated by Compose
```

---

## Files in this directory

| File | Purpose |
|------|---------|
| `devcontainer.json` | VS Code Dev Containers configuration |
| `docker-compose.yml` | Compose file: dev container + PostgreSQL 18 + Neo4j 5 |
| `.env.example` | Template – copy to `.env` and edit |
| `environments-ollama.json` | Semiont env config using Ollama |
| `environments-lmstudio.json` | Semiont env config using LM Studio |
| `README.md` | This file |
