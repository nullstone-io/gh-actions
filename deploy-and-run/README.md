# deploy-and-run

Composite action that deploys a Nullstone app and then executes a follow-up command via `nullstone run`. Generic by design — covers DB migrations, seed jobs, batch tasks, and any "deploy + invoke" pattern.

## Inputs

| Input | Required | Notes |
| -- | -- | -- |
| `app` | yes | Nullstone app to deploy |
| `command` | yes | Command passed to `nullstone run --app=<app>` |
| `env` | yes | Target Nullstone environment |
| `env-vars` | no | Newline-separated `KEY=VALUE` pairs, each passed as `--env-var` to the `nullstone deploy` step |
| `run-env-vars` | no | Newline-separated `KEY=VALUE` pairs, each passed as `--env-var` to the `nullstone run` step |

## Environment

Reads `NULLSTONE_ORG`, `NULLSTONE_STACK`, and `NULLSTONE_API_KEY` from the workflow environment. See the [top-level README](../README.md#consumer-convention) for the convention.

## Examples

Migrations:

```yaml
db-migrate:
  needs: [publish, iac-sync]
  runs-on: ubuntu-latest
  steps:
    - uses: nullstone-io/gh-actions/deploy-and-run@v1
      with:
        env: ${{ inputs.env }}
        app: taco-migrations
        command: migrate up
```

Seeder (same action, different inputs):

```yaml
seed:
  runs-on: ubuntu-latest
  steps:
    - uses: nullstone-io/gh-actions/deploy-and-run@v1
      with:
        env: ${{ inputs.env }}
        app: taco-seeder
        command: seed all
```

Setting env vars. `env-vars` is applied to the `nullstone deploy` step, while `run-env-vars`
is applied to the follow-up `nullstone run` step:

```yaml
db-migrate:
  runs-on: ubuntu-latest
  steps:
    - uses: nullstone-io/gh-actions/deploy-and-run@v1
      with:
        env: ${{ inputs.env }}
        app: taco-migrations
        command: migrate up
        env-vars: |
          LOG_LEVEL=debug
          RELEASE_SHA=${{ github.sha }}
        run-env-vars: |
          MIGRATE_BATCH_SIZE=500
```

## Behavior

1. Checks out the repo.
2. Sets up the Nullstone CLI.
3. Runs `nullstone deploy --app=<app>`.
4. Runs `nullstone run --app=<app> <command>`.

The action fails fast if the deploy step fails, so the run step only executes against a freshly deployed app.
