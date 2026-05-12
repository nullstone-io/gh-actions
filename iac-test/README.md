# iac-test

Composite action that runs `nullstone iac test` to validate the IaC config (`.nullstone/*.yml`) in the consumer's repo against a target environment. Designed to run on pull requests, typically across a matrix of environments.

## Inputs

| Input | Required | Notes |
| -- | -- | -- |
| `env` | yes | Target Nullstone environment |

## Environment

Reads `NULLSTONE_ORG`, `NULLSTONE_STACK`, and `NULLSTONE_API_KEY` from the workflow environment. See the [top-level README](../README.md#consumer-convention) for the convention.

## Example

```yaml
name: IaC Test

on:
  pull_request:
    types: [opened, synchronize, reopened]
    paths:
      - ".nullstone/*.yml"
      - ".github/workflows/iac-test.yaml"

env:
  NULLSTONE_ORG: ${{ vars.NULLSTONE_ORG }}
  NULLSTONE_STACK: ${{ vars.NULLSTONE_STACK }}
  NULLSTONE_API_KEY: ${{ secrets.NULLSTONE_API_KEY }}

jobs:
  iac-test:
    name: iac-test (${{ matrix.env }})
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        env: [dev, prod]
    steps:
      - uses: nullstone-io/gh-actions/iac-test@v1
        with:
          env: ${{ matrix.env }}
```

## Behavior

1. Checks out the repo (so `nullstone iac test` can read `.nullstone/` config).
2. Sets up the Nullstone CLI.
3. Runs `nullstone iac test`. Fails the job if any IaC config is invalid for the target environment.
