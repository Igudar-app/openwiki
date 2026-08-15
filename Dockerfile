# syntax=docker/dockerfile:1

# Builder stage: install deps, build dist, prune dev dependencies.
FROM node:22-bookworm-slim AS builder
WORKDIR /src
RUN npm install --global pnpm@10.33.2
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile
COPY . .
RUN pnpm run build && pnpm prune --prod

# Runtime stage: the openwiki CLI plus the optional mermaid/jsdom validators,
# with git so code mode can inspect the repository it documents.
FROM node:22-bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /opt/openwiki
COPY --from=builder /src/package.json ./
COPY --from=builder /src/dist ./dist
COPY --from=builder /src/skills ./skills
COPY --from=builder /src/node_modules ./node_modules
COPY LICENSE README.md ./
# --ignore-scripts skips prepack (which would rebuild without devDependencies);
# the global install links the bin and resolves mermaid/jsdom from the same
# global node_modules.
RUN npm install --ignore-scripts --global . mermaid@11.16.0 jsdom@29.1.1
ENV OPENWIKI_TELEMETRY_DISABLED=1
ENTRYPOINT ["openwiki"]
