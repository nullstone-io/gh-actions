# gh-actions

Catalog of reusable composite GitHub Actions for assembling a Nullstone deploy pipeline. Each subdirectory is its own action — reference it by path-qualified `uses:` URL.

## Actions

| Action | Purpose |
| -- | -- |
| [`publish-module`](publish-module/) | Publish a Nullstone IaC module if its source files changed in the most recent commit (exposes `changed` output) |
| [`build-publish-docker-app`](build-publish-docker-app/) | Build a single app's container image with Buildx and push it to the Nullstone artifact registry |
| [`iac-sync`](iac-sync/) | Run `nullstone iac-sync` for a target environment |
| [`deploy-and-run`](deploy-and-run/) | Deploy a Nullstone app and execute a follow-up command (migrations, seeds, batch jobs) |
| [`deploy-app`](deploy-app/) | Deploy a single Nullstone app via `nullstone deploy` |

## Consumer convention

Each action reads Nullstone credentials from the environment. Surface them once at the workflow (or job) level — the per-call YAML never has to mention them:

```yaml
env:
  NULLSTONE_ORG: ${{ vars.NULLSTONE_ORG }}
  NULLSTONE_STACK: ${{ vars.NULLSTONE_STACK }}
  NULLSTONE_API_KEY: ${{ secrets.NULLSTONE_API_KEY }}
```

`secrets` context is not available inside a composite action, so this `env:` block is required wherever these actions are used.

## End-to-end example

```yaml
name: Deploy Taco

on:
  workflow_call:
    inputs:
      env:
        type: string
        required: true
      ui-build-args:
        type: string
        required: true

env:
  NULLSTONE_ORG: ${{ vars.NULLSTONE_ORG }}
  NULLSTONE_STACK: ${{ vars.NULLSTONE_STACK }}
  NULLSTONE_API_KEY: ${{ secrets.NULLSTONE_API_KEY }}

jobs:
  publish-modules:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        dir:
          - workflows/order-router
          - workflows/inventory-sync
    steps:
      - uses: nullstone-io/gh-actions/publish-module@v1
        with:
          dir: ${{ matrix.dir }}

  publish:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        include:
          - app: taco-api
            dockerfile: ./Dockerfile
          - app: taco-migrations
            dockerfile: ./migrations.Dockerfile
          - app: taco-ui
            dockerfile: ./ui/apps/web/Dockerfile
            build-args: ${{ inputs.ui-build-args }}
    steps:
      - uses: nullstone-io/gh-actions/build-publish-docker-app@v1
        with:
          env: ${{ inputs.env }}
          app: ${{ matrix.app }}
          dockerfile: ${{ matrix.dockerfile }}
          build-args: ${{ matrix.build-args }}

  iac-sync:
    needs: [publish]
    runs-on: ubuntu-latest
    steps:
      - uses: nullstone-io/gh-actions/iac-sync@v1
        with:
          env: ${{ inputs.env }}

  db-migrate:
    needs: [publish, iac-sync]
    runs-on: ubuntu-latest
    steps:
      - uses: nullstone-io/gh-actions/deploy-and-run@v1
        with:
          env: ${{ inputs.env }}
          app: taco-migrations
          command: migrate up

  deploy:
    needs: [publish, db-migrate]
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        app:
          - taco-ui
          - taco-api
    steps:
      - uses: nullstone-io/gh-actions/deploy-app@v1
        with:
          env: ${{ inputs.env }}
          app: ${{ matrix.app }}
```

## Versioning

Tags are monorepo-wide — `v1.0.0` covers every action at the moment that tag points to. Most consumers should pin to the moving major (`@v1`); security-sensitive consumers can pin to a SHA (`@<sha>`). Breaking changes in any action bump the major for all of them.

Development happens on the `release/v1` branch; releases are tagged as `v1.x.y` from there and the `v1` tag is force-moved to the latest compatible release.

## Why composite actions, not reusable workflows

- Native `strategy.matrix` and `if:` at the call site, with no JSON-encoded list inputs.
- Shorter `uses:` URLs.

The cost (declaring `runs-on:` + `steps:` and surfacing secrets via an `env:` block instead of `secrets: inherit`) is paid once per consumer workflow, not once per call site.

## Marketplace

Subdirectory composite actions are not eligible for the GitHub Marketplace — only repo-root `action.yml` files are. Consumers reference each action by its path-qualified `uses:` URL. The `branding` fields in each `action.yml` are kept as no-ops in case we ever pivot to per-action repos.
