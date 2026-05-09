# build-publish-docker-app

Composite action that builds a single app's container image with Buildx and pushes it to the Nullstone artifact registry.

## Inputs

| Input | Required | Default | Notes |
| -- | -- | -- | -- |
| `app` | yes | — | Nullstone app name (also used as the image tag) |
| `dockerfile` | yes | — | Path to the Dockerfile |
| `context` | no | `.` | Docker build context |
| `build-args` | no | `''` | Newline-separated `KEY=VALUE` pairs passed as `--build-arg` |
| `env` | yes | — | Target Nullstone environment |

## Environment

Reads `NULLSTONE_ORG`, `NULLSTONE_STACK`, and `NULLSTONE_API_KEY` from the workflow environment. See the [top-level README](../README.md#consumer-convention) for the convention.

## Example

```yaml
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
          build-args: |
            NEXT_PUBLIC_ENV=development
            GIT_SHA=${{ github.sha }}
  steps:
    - uses: nullstone-io/gh-actions/build-publish-docker-app@v1
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
4. Pushes to Nullstone via `nullstone push --source=<app> --app=<app>`.
