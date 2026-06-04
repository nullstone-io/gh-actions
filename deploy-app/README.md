# deploy-app

Composite action that deploys a single Nullstone app via `nullstone deploy`. Intended to be called once per matrix leg by the consumer.

## Inputs

| Input      | Required | Default   | Notes                                                                                                  |
|------------|----------|-----------|--------------------------------------------------------------------------------------------------------|
| `app`      | yes      | —         | Nullstone app name                                                                                     |
| `env`      | yes      | —         | Target Nullstone environment                                                                           |
| `wait`     | no       | `'false'` | When `'true'`, passes `--wait` to `nullstone deploy` so the step blocks until the deployment completes |
| `env-vars` | no       | `''`      | Newline-separated `KEY=VALUE` pairs, each passed as `--env-var` to `nullstone deploy`                  |

## Environment

Reads `NULLSTONE_ORG`, `NULLSTONE_STACK`, and `NULLSTONE_API_KEY` from the workflow environment. See the [top-level README](../README.md#consumer-convention) for the convention.

## Example

```yaml
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

Passing env vars to the deployment:

```yaml
steps:
  - uses: nullstone-io/gh-actions/deploy-app@v1
    with:
      env: ${{ inputs.env }}
      app: taco-api
      env-vars: |
        LOG_LEVEL=debug
        FEATURE_FLAG=on
        RELEASE_SHA=${{ github.sha }}
```

## Behavior

1. Sets up the Nullstone CLI (no checkout required — `nullstone deploy` doesn't read repo files).
2. Runs `nullstone deploy` with `NULLSTONE_APP` and `NULLSTONE_ENV` set from inputs.
