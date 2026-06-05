# iac-sync

Composite action that runs `nullstone iac sync` to reconcile Nullstone's IaC config (apps, capabilities, connections) with what's declared in the consumer's repo.

## Inputs

| Input        | Required  | Notes                                                                                                     |
|--------------|-----------|-----------------------------------------------------------------------------------------------------------|
| `env`        | yes       | Target Nullstone environment                                                                              |
| `auto-plan`  | no        | Queue an infra-update Run on each workspace where IaC changes are detected (Run is left pending approval) |
| `auto-apply` | no        | Auto-approve any infra-update Run created by the sync (implies `--auto-plan`)                             |

## Environment

Reads `NULLSTONE_ORG`, `NULLSTONE_STACK`, and `NULLSTONE_API_KEY` from the workflow environment. See the [top-level README](../README.md#consumer-convention) for the convention.

## Example

```yaml
iac-sync:
  needs: [publish]
  runs-on: ubuntu-latest
  steps:
    - uses: nullstone-io/gh-actions/iac-sync@v1
      with:
        env: ${{ inputs.env }}
```

## Behavior

1. Checks out the repo (so `nullstone iac sync` can read `.nullstone/` config).
2. Sets up the Nullstone CLI.
3. Runs `nullstone iac sync`. No-ops cleanly when there are no IaC changes to apply.
