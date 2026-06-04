# publish-module

Composite action that publishes a single Nullstone IaC module if its source files changed in the most recent commit. Exposes a `changed` output so downstream jobs can gate on it.

## Inputs

| Input     | Required  | Notes                                                                                                                                                                                                         |
|-----------|-----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `dir`     | yes       | Path (relative to repo root) of the module — also doubles as the display label                                                                                                                                |
| `version` | no        | Semver version for the module, passed as `--version` (default `next-patch`). `'next-patch'` bumps the patch component of the latest version; `'next-build'` appends `+<build>` using the short Git commit SHA |
| `if`      | no        | Only publish when the condition is met, passed as `--if`. `'checksum-changed'` skips publishing when the packaged tarball matches the latest published version                                                |

## Outputs

| Output | Notes |
| -- | -- |
| `changed` | `"true"` if the module's source files changed in `HEAD~1..HEAD`, `"false"` otherwise |
| `version` | Module version emitted by `nullstone modules publish` on success (empty when the publish step is skipped) |

## Environment

Reads `NULLSTONE_ORG`, `NULLSTONE_STACK`, and `NULLSTONE_API_KEY` from the workflow environment. See the [top-level README](../README.md#consumer-convention) for the convention.

## Example

```yaml
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
```

## Behavior

1. Checks out the repo at `github.sha` with `fetch-depth: 2` so the diff against `HEAD~1` works.
2. Diffs `HEAD~1..HEAD` against `dir`; sets the `changed` output accordingly.
3. If `changed == 'true'`, sets up the Nullstone CLI and runs `nullstone modules publish --version=next-patch` from `dir`.
4. If `changed == 'false'`, skips publishing — exits cleanly so consumers can use the action unconditionally inside a matrix.

## Known gap (post-v1)

Change-detection only diffs `HEAD~1..HEAD`. If a publish fails transiently and the next commit doesn't touch the module dir, the failure won't be retried. Future fix: gate against the last successfully published SHA (registry lookup) or expose a `force-publish` input.
