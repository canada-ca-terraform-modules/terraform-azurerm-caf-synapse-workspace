# `test/live/` - live-test harness

A live, real-Azure-resource harness used by the `live-test` PR check (see
the [`live-test-actions`](https://github.com/canada-ca-terraform-modules/live-test-actions)
repo and this module's own `.github/workflows/live-test.yml`) to prove that
an open PR doesn't destroy or replace a resource a real consumer already
has running. It is **not** a substitute for either of the module's other
two test surfaces:

- **`tests/*.tftest.hcl`** - mock-based unit tests (`terraform test`, no
  provider credentials, no live Azure resources). Covers naming, defaults,
  and validation logic on every PR via `terraform-ci.yml`. Run these first;
  they're fast and free.
- **`ESLZ/`** - a usage example showing the map-based (`for_each`) blueprint
  pattern consumers actually wire this module into. Not exercised by CI at
  all; documentation only.
- **`test/live/`** (this directory) - a single, real instance of the module
  applied against a disposable Azure sandbox subscription. Used by CI to
  diff the PR's plan against a live baseline, and can be run manually by a
  maintainer the same way.

## What's here

| File | Purpose |
|---|---|
| `main.tf` | Module block with `source = "../../"` (a relative path, not a pinned `?ref` - "baseline" and "PR" are just two on-disk checkouts of this repo), the `azurerm`/`random` provider config, and an empty `backend "local" {}` block (path supplied at `init` time - see below). |
| `test_dependencies.tf` | A dedicated, throwaway resource group + storage account + ADLS Gen2 filesystem this harness owns outright - never shared/production resources. Names are suffixed with `var.pr_number` so concurrently open PRs never collide. Also supplies the `resource_groups` map the module requires, including a dummy `Keyvault` entry (see inline comment - the module eagerly computes a Key Vault name-derivation local regardless of whether a real Key Vault secret gets created). |
| `variables.tf` | `env`, `group`, `project`, `location` (defaults to `canadacentral`), `tags`, `pr_number` (defaults to `"manual"`), and `synapse` (typed `any`, merged with the computed `resource_group`/`data_lake` values in `main.tf` before being passed to the module). |
| `config/synapse_workspace.tfvars` | One representative real-usage fixture: explicit `sql_admin_password` (so no live Key Vault lookup is needed) and explicit `identity`/`public_network_access_enabled` (works around real Azure API validation errors the module's own defaults hit - see inline comments in the fixture). |

No Terragrunt anywhere under this directory - a single harness per repo has
no cross-harness DRY need.

## Module-specific notes

- `storage_data_lake_gen2_filesystem_id` is Required/ForceNew on
  `azurerm_synapse_workspace`, so this harness creates its own ADLS Gen2
  filesystem rather than depending on any shared storage account.
- The module's `data_lake` input accepts either a direct filesystem
  resource ID (a string containing `https`) or a lookup into a `data-lake`
  map. This harness always supplies the direct resource ID from its own
  `azurerm_storage_data_lake_gen2_filesystem.live_test`, so `data-lake` is
  passed as an empty map (`{}`) and never used for lookup.
- `azure_devops_repo`/`github_repo` blocks are not exercised by this
  harness - the module's own `lifecycle.ignore_changes` on those blocks (see
  `module.tf`) means live-Azure repo-link drift isn't something a
  Terraform-only harness can observe anyway.

## Running it manually

Requires your own `az login` session against the sandbox subscription (CI
uses OIDC instead).

```bash
cd test/live
terraform init
terraform plan  -var-file=config/synapse_workspace.tfvars
terraform apply -var-file=config/synapse_workspace.tfvars
```

Confirm only the live-test resource group, storage account, gen2
filesystem, and `module.synapse_workspace` are planned/applied, then tear it
down:

```bash
terraform destroy -var-file=config/synapse_workspace.tfvars
```

No `.tfstate` file is ever committed under `test/live/` - every run is
fully ephemeral, whether run by CI or by hand.

## Two-checkout state isolation (baseline vs. PR)

CI proves a PR isn't a breaking change by applying the target branch as a
live baseline, then plan/apply-ing the PR branch's checkout of this same
harness against that same live state - two on-disk checkouts of this repo,
one shared external state file, no state copying between them:

```bash
# Directory A: PR branch checkout, directory B: target branch checkout.
STATE=$RUNNER_TEMP/live-test-<pr-number>.tfstate

# 1. Baseline apply, from B.
cd B/test/live
terraform init -backend-config="path=$STATE"
terraform apply -var-file=config/synapse_workspace.tfvars -var="pr_number=<pr-number>"

# 2. PR plan (and, in CI, apply), from A, against the same state file.
cd A/test/live
terraform init -backend-config="path=$STATE"
terraform plan -var-file=config/synapse_workspace.tfvars -var="pr_number=<pr-number>"

# 3. Always tear down from A once the run finishes (`if: always()` in CI).
terraform destroy -var-file=config/synapse_workspace.tfvars -var="pr_number=<pr-number>"
```

`pr_number` (`TF_VAR_pr_number` in CI, sourced from `github.event.number`)
suffixes every `test_dependencies.tf` resource name, so two concurrently
open PRs against this module - each pointed at their own
`live-test-<pr-number>.tfstate` - never collide on the same sandbox resource
group or storage account.
