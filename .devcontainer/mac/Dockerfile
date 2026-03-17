# Semiont Mac Dev Container
#
# Lightweight multi-arch image built locally by Docker Desktop.
# PostgreSQL and Neo4j run as separate services in docker-compose.yml,
# so this image only needs Node.js and native build tools.
#
# Supports both linux/amd64 and linux/arm64 (Apple Silicon) because
# the Microsoft base image is multi-arch.
FROM mcr.microsoft.com/devcontainers/typescript-node:1-22-bookworm

USER root

# Install native build tools required by some npm packages (node-gyp etc.)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        python3 \
        python3-pip \
        libssl-dev && \
    rm -rf /var/lib/apt/lists/*

# Pre-create workspace directories owned by the `node` user so that
# Docker-managed named volumes (node_modules, semiont_project) are
# initialized with the right ownership when they are first mounted.
RUN mkdir -p /workspace/node_modules /workspace/project && \
    chown -R node:node /workspace

WORKDIR /workspace

USER node
