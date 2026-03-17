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
| Ollama **or** LM Studio | Any recent | Running on your Mac |

---

## Quick Start

### 1. Run the volume setup script (once)

```bash
bash scripts/setup-volumes.sh
```

This creates the required Docker volumes, local data directories, and a starter `.env` file at `.devcontainer/mac/.env`.

### 2. Choose your LLM provider

Edit `.devcontainer/mac/.env`:

#### Option A – Ollama (default)

```dotenv
INFERENCE_TYPE=ollama
OLLAMA_ENDPOINT=http://host.docker.internal:11434
OLLAMA_MODEL=llama3.2       # any model you have pulled
```

Make sure Ollama is running on your Mac and the model is available:

```bash
ollama serve          # start the server (if not already running)
ollama pull llama3.2  # download the model
```

#### Option B – LM Studio

```dotenv
INFERENCE_TYPE=lmstudio
LMSTUDIO_ENDPOINT=http://host.docker.internal:1234/v1
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

The container will:
- Pull the pre-built dev image
- Start a PostgreSQL container alongside
- Run `.devcontainer/setup.sh` (installs dependencies, builds packages, provisions services, creates an admin user)

Estimated first-run time: **5–10 minutes**.

### 4. Copy the environment config for your LLM

The `setup.sh` script copies `environments/local.json` from the devcontainer defaults. For the Mac-native LLM providers, swap in the right template **inside the container**:

```bash
# Inside the container terminal

# For Ollama:
cp /workspace/.devcontainer/mac/environments-ollama.json \
   /workspace/project/environments/local.json

# For LM Studio:
cp /workspace/.devcontainer/mac/environments-lmstudio.json \
   /workspace/project/environments/local.json
```

Then re-provision the backend so it picks up the new inference config:

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

---

## How host LLM access works

Docker Desktop for Mac automatically resolves the hostname `host.docker.internal` to the IP address of your Mac. Both environment configs use this hostname so the backend container can reach Ollama or LM Studio without any extra port-forwarding.

```
┌──────────────────────────────────────┐
│  Mac host                            │
│                                      │
│  Ollama  :11434  ─────────────────┐  │
│  LM Studio :1234/v1  ─────────┐   │  │
│                                │   │  │
│  ┌─────────────────────────┐   │   │  │
│  │  Docker Desktop         │   │   │  │
│  │                         │   │   │  │
│  │  devcontainer  ─────────┼───┘   │  │
│  │      ↕ host.docker      │       │  │
│  │      .internal          ├───────┘  │
│  │                         │          │
│  │  postgres :5432         │          │
│  └─────────────────────────┘          │
└──────────────────────────────────────┘
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

- Confirm the service is running on your Mac (`ollama ps` or check LM Studio).
- Verify the port: Ollama defaults to **11434**, LM Studio defaults to **1234**.
- Test from inside the container: `curl http://host.docker.internal:11434/api/tags`

### Container can't reach PostgreSQL

PostgreSQL runs as a Docker Compose service named `postgres`. The `DATABASE_URL` in the container already points there. If it fails:

```bash
docker compose -f .devcontainer/mac/docker-compose.yml ps
```

### Resetting volumes (start fresh)

```bash
docker compose -f .devcontainer/mac/docker-compose.yml down -v
bash scripts/setup-volumes.sh   # re-create volumes
```

Then reopen the container in VS Code.

---

## Files in this directory

| File | Purpose |
|------|---------|
| `devcontainer.json` | VS Code Dev Containers configuration |
| `docker-compose.yml` | Compose file: dev container + PostgreSQL |
| `.env.example` | Template – copy to `.env` and edit |
| `environments-ollama.json` | Semiont env config using Ollama |
| `environments-lmstudio.json` | Semiont env config using LM Studio |
| `README.md` | This file |
