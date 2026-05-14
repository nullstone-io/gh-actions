# build-deploy-docker-app

Composite action that builds a single app's container image with Buildx, pushes it to the Nullstone artifact registry, and then deploys the app. Combines [`build-publish-docker-app`](../build-publish-docker-app/) and [`deploy-app`](../deploy-app/) into one step.

## Inputs

| Input | Required | Default | Notes |
| -- | -- | -- | -- |
| `app` | yes | — | Nullstone app name (also used as the image tag) |
| `dockerfile` | yes | — | Path to the Dockerfile |
| `context` | no | `.` | Docker build context |
| `build-args` | no | `''` | Newline-separated `KEY=VALUE` pairs passed as `--build-arg` |
| `env` | yes | — | Target Nullstone environment |
| `version` | no | `''` | Version label for the artifact (defaults to the commit SHA) |
| `unique` | no | `'false'` | Always push with a unique version; appends `-<count>` if the version already exists |
| `wait` | no | `'false'` | When `'true'`, passes `--wait` to `nullstone deploy` so the step blocks until the deployment completes |

## Outputs

| Output | Notes |
| -- | -- |
| `version` | Artifact version emitted by `nullstone push` on success |

## Environment

Reads `NULLSTONE_ORG`, `NULLSTONE_STACK`, and `NULLSTONE_API_KEY` from the workflow environment. See the [top-level README](../README.md#consumer-convention) for the convention.

## Example

```yaml
build-deploy:
  runs-on: ubuntu-latest
  strategy:
    fail-fast: false
    matrix:
      include:
        - app: taco-api
          dockerfile: ./Dockerfile
        - app: taco-ui
          dockerfile: ./ui/apps/web/Dockerfile
          build-args: |
            NEXT_PUBLIC_ENV=development
            GIT_SHA=${{ github.sha }}
  steps:
    - uses: nullstone-io/gh-actions/build-deploy-docker-app@v1
      with:
        env: ${{ inputs.env }}
        app: ${{ matrix.app }}
        dockerfile: ${{ matrix.dockerfile }}
        build-args: ${{ matrix.build-args }}
```

## Behavior

1. Checks out the repo at `github.sha`.
2. Sets up Docker Buildx and the Nullstone CLI.
3. Builds the image locally (`load: true`, `push: false`) tagged as `${{ inputs.app }}`, with GHA layer caching (`type=gha`).
4. Pushes to Nullstone via `nullstone push --source=<app>`, capturing the emitted version as the `version` output.
5. Deploys the app via `nullstone deploy --version <version>`, using the exact version emitted by step 4.

## When to use this vs. the split actions

Use this action when a single app's build, publish, and deploy run together in one job with no intervening steps (e.g., no IaC sync, no DB migration). When you need to fan out a publish step, run `iac-sync`, run migrations, and then deploy in a separate job, use [`build-publish-docker-app`](../build-publish-docker-app/) and [`deploy-app`](../deploy-app/) separately.
