<!-- markdownlint-disable MD033 MD041 -->

<div align="center">

# OpenWiki — Igudar fork

### The self-maintaining wiki. Built for agents, explored by humans.

A fork of [langchain-ai/openwiki](https://github.com/langchain-ai/openwiki) that adds a **native DeepSeek provider**, published by the Igudar org for use in the [Igudar platform](https://github.com/Igudar-app/platform) documentation pipeline.

[![License: MIT](https://img.shields.io/badge/license-MIT-1A6FB5.svg?style=flat&labelColor=030710)](./LICENSE)
[![Node](https://img.shields.io/node/v/@igudar-app/openwiki?style=flat&labelColor=030710)](https://nodejs.org)
[![Upstream](https://img.shields.io/badge/upstream-langchain--ai%2Fopenwiki-1A6FB5.svg?style=flat&labelColor=030710)](https://github.com/langchain-ai/openwiki)

</div>

OpenWiki is a CLI that writes and maintains a wiki for your codebase. An agent reads your sources, synthesizes a linked Markdown wiki you own, and keeps it current on every change. This fork is maintained by **Igudar** to power the auto-generated documentation of the Igudar platform with DeepSeek inference.

## Why this fork exists

Upstream OpenWiki does not ship a `deepseek` provider. The Igudar platform generates and refreshes its repository wiki on a daily schedule (GitHub Actions), and its inference budget is DeepSeek. This fork adds DeepSeek as a first-class provider — with a preset model list, credential handling, and CI workflow generation — so the pipeline needs no `openai-compatible` shim.

**Changes vs upstream `openwiki@0.3.1`:**

- **`deepseek` provider** in `src/constants.ts` — `DEEPSEEK_API_KEY` credential, base URL `https://api.deepseek.com/v1` (overridable via `DEEPSEEK_BASE_URL`), preset models `deepseek-v4-flash` / `deepseek-v4-pro`.
- **Auto-detection** — `resolveConfiguredProvider` selects `deepseek` when `OPENWIKI_PROVIDER` is unset and only `DEEPSEEK_API_KEY` is present.
- **Credential management** — `DEEPSEEK_API_KEY` / `DEEPSEEK_BASE_URL` registered in `MANAGED_ENV_KEYS` (diagnostics, redaction, `~/.openwiki/.env` persistence).
- **Generated CI workflow** — `openwiki code --init` now emits a workflow that installs `@igudar-app/openwiki` from GitHub Packages and runs with the DeepSeek provider by default.
- **Scoped package name** — published as `@igudar-app/openwiki` (never collides with the public `openwiki` package).

## Install

From the GitHub Packages registry (public package, requires Node ≥ 22):

```sh
npm install -g @igudar-app/openwiki@0.4.1
```

## Quick start

Generate a wiki for the current repository:

```sh
openwiki code --init
```

Provide the DeepSeek credentials (the wizard can also save them to `~/.openwiki/.env`):

```sh
export OPENWIKI_PROVIDER=deepseek
export DEEPSEEK_API_KEY=sk-...
export OPENWIKI_MODEL_ID=deepseek-v4-flash
```

Run once (non-interactive) and exit:

```sh
openwiki code --update --print
```

## DeepSeek provider reference

| Setting             | Value                                                    |
| ------------------- | -------------------------------------------------------- |
| `OPENWIKI_PROVIDER` | `deepseek`                                               |
| `DEEPSEEK_API_KEY`  | Your DeepSeek API key                                    |
| `DEEPSEEK_BASE_URL` | Optional override; default `https://api.deepseek.com/v1` |
| `OPENWIKI_MODEL_ID` | `deepseek-v4-flash` (default) or `deepseek-v4-pro`       |

Any other OpenAI-compatible provider can still be used via the upstream `openai-compatible` provider — this fork only adds to the provider registry, it removes nothing.

## Scheduled updates (GitHub Actions)

Keep the wiki current with a daily job that opens a docs PR:

```yaml
on:
  schedule:
    - cron: "0 8 * * *"
  workflow_dispatch:
jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: actions/setup-node@v4
        with:
          node-version: "22"
          registry-url: https://npm.pkg.github.com
          scope: "@igudar-app"
      - name: Install OpenWiki
        run: npm install --global @igudar-app/openwiki@0.4.1 mermaid@11.16.0 jsdom@29.1.1
        env:
          NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      - name: Run OpenWiki
        run: openwiki code --update --print
        env:
          OPENWIKI_PROVIDER: deepseek
          DEEPSEEK_API_KEY: ${{ secrets.DEEPSEEK_API_KEY }}
          OPENWIKI_MODEL_ID: deepseek-v4-flash
```

For consuming repositories, set `DEEPSEEK_API_KEY` as a repository secret. A copy of this file lives at [`examples/openwiki-update.yml`](./examples/openwiki-update.yml).

## Publishing to GitHub Packages

`.github/workflows/publish.yml` builds, tests, and publishes `@igudar-app/openwiki` to `npm.pkg.github.com` on every push to `main`. Publishing uses the `GITHUB_TOKEN` (`packages: write` permission) — no PAT needed. To release a new version, bump `version` in `package.json` and merge to `main`.

## Development

```sh
pnpm install --frozen-lockfile
pnpm run typecheck
pnpm test
pnpm run build
```

## Syncing with upstream

This fork tracks `langchain-ai/openwiki` (`main`). When rebasing, keep the `deepseek` blocks in `src/constants.ts`, `src/env.ts`, `src/version.ts`, `src/code-mode.ts`, and the provider tests in `test/constants.test.ts` / `test/code-mode.test.ts`.

## License

[MIT](./LICENSE) — same as upstream. See the [upstream project](https://github.com/langchain-ai/openwiki) for the original source.
