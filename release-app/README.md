# release-app

Composite action that releases a single Nullstone app via `nullstone release`. A release runs an infra-update when there are outstanding workspace changes and deploys when the app version has changed, producing the optimal path to make both infra and app code live. Intended to be called once per matrix leg by the consumer.

## Inputs

| Input          | Required | Default   | Notes                                                                                                                                   |
|----------------|----------|-----------|-----------------------------------------------------------------------------------------------------------------------------------------|
| `app`          | yes      | —         | Nullstone app name                                                                                                                      |
| `env`          | yes      | —         | Target Nullstone environment                                                                                                            |
| `version`      | no       | `''`      | Label for the release, passed as `--version` (defaults to the commit SHA of the current repo)                                           |
| `auto-approve` | no       | `'false'` | When `'true'`, passes `--auto-approve` to `nullstone release` to skip approvals on the infra-update (requires proper stack permissions) |
| `wait`         | no       | `'false'` | When `'true'`, passes `--wait` to `nullstone release` so the step blocks until the release completes                                    |
| `env-vars`     | no       | `''`      | Newline-separated `KEY=VALUE` pairs, each passed as `--env-var` to `nullstone release`                                                  |

## Environment

Reads `NULLSTONE_ORG`, `NULLSTONE_STACK`, and `NULLSTONE_API_KEY` from the workflow environment. See the [top-level README](../README.md#consumer-convention) for the convention.

## Example

```yaml
release:
  needs: [publish, db-migrate]
  runs-on: ubuntu-latest
  strategy:
    fail-fast: false
    matrix:
      app:
        - taco-ui
        - taco-api
  steps:
    - uses: nullstone-io/gh-actions/release-app@v1
      with:
        env: ${{ inputs.env }}
        app: ${{ matrix.app }}
```

Passing env vars to the release:

```yaml
steps:
  - uses: nullstone-io/gh-actions/release-app@v1
    with:
      env: ${{ inputs.env }}
      app: taco-api
      env-vars: |
        LOG_LEVEL=debug
        FEATURE_FLAG=on
        RELEASE_SHA=${{ github.sha }}
```

## Behavior

1. Sets up the Nullstone CLI (no checkout required — `nullstone release` doesn't read repo files).
2. Runs `nullstone release` with `NULLSTONE_APP` and `NULLSTONE_ENV` set from inputs.

## When to use this vs. `deploy-app`

Use [`deploy-app`](../deploy-app/) when you only need to deploy already-published code. Use `release-app` when you want Nullstone to reconcile infra changes and app code in a single step — it runs an infra-update if there are outstanding workspace changes and a deploy if the app version has changed.
