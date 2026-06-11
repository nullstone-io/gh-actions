# release-and-run

Composite action that releases a Nullstone app (infra-update + deploy) and then executes a follow-up command via `nullstone run`. The release counterpart of [`deploy-and-run`](../deploy-and-run/) — use it when the follow-up command must run against an app whose infra changes and code are both reconciled in a single step. Covers DB migrations, seed jobs, batch tasks, and any "release + invoke" pattern.

## Inputs

| Input          | Required | Default   | Notes                                                                                                                                   |
|----------------|----------|-----------|-----------------------------------------------------------------------------------------------------------------------------------------|
| `app`          | yes      | —         | Nullstone app to release                                                                                                                |
| `command`      | yes      | —         | Command passed to `nullstone run --app=<app>` after the release                                                                         |
| `env`          | yes      | —         | Target Nullstone environment                                                                                                            |
| `version`      | no       | `''`      | Label for the release, passed as `--version` (defaults to the commit SHA of the current repo)                                           |
| `auto-approve` | no       | `'false'` | When `'true'`, passes `--auto-approve` to `nullstone release` to skip approvals on the infra-update (requires proper stack permissions) |
| `container`    | no       | `''`      | Select a specific container within a task or pod, passed as `--container` to the `nullstone run` step                                   |
| `env-vars`     | no       | `''`      | Newline-separated `KEY=VALUE` pairs, each passed as `--env-var` to the `nullstone release` step                                         |
| `run-env-vars` | no       | `''`      | Newline-separated `KEY=VALUE` pairs, each passed as `--env-var` to the `nullstone run` step                                             |

## Environment

Reads `NULLSTONE_ORG`, `NULLSTONE_STACK`, and `NULLSTONE_API_KEY` from the workflow environment. See the [top-level README](../README.md#consumer-convention) for the convention.

## Examples

Migrations after a release:

```yaml
db-migrate:
  needs: [publish, iac-sync]
  runs-on: ubuntu-latest
  steps:
    - uses: nullstone-io/gh-actions/release-and-run@v1
      with:
        env: ${{ inputs.env }}
        app: taco-migrations
        command: migrate up
```

Setting env vars. `env-vars` is applied to the `nullstone release` step, while `run-env-vars`
is applied to the follow-up `nullstone run` step:

```yaml
db-migrate:
  runs-on: ubuntu-latest
  steps:
    - uses: nullstone-io/gh-actions/release-and-run@v1
      with:
        env: ${{ inputs.env }}
        app: taco-migrations
        command: migrate up
        auto-approve: 'true'
        env-vars: |
          LOG_LEVEL=debug
          RELEASE_SHA=${{ github.sha }}
        run-env-vars: |
          MIGRATE_BATCH_SIZE=500
```

## Behavior

1. Checks out the repo.
2. Sets up the Nullstone CLI.
3. Runs `nullstone release --app=<app> --wait` (infra-update when there are outstanding workspace changes, deploy when the app version has changed). The `--wait` flag always blocks until the release completes, since the follow-up command must run against a fully released app.
4. Runs `nullstone run --app=<app> <command>`.

The action fails fast if the release step fails, so the run step only executes against a freshly released app.

## When to use this vs. `deploy-and-run`

Use [`deploy-and-run`](../deploy-and-run/) when you only need to deploy already-published code before the follow-up command. Use `release-and-run` when you want Nullstone to reconcile infra changes and app code in a single step before running the command.
