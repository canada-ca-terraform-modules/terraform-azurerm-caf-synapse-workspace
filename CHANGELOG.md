# Changelog

All notable changes to this module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## v1.2.0 - 2026-08-12

### Changed

- Bumped `azurerm` provider constraint from `~> 4.0` to `~> 5.0` (target `5.0.1`). Gap analysis against the azurerm 5.0 upgrade guide and the `azurerm_synapse_workspace`, `azurerm_synapse_firewall_rule`, `azurerm_key_vault_secret`, `azurerm_key_vault` (data source), and `random_password` schemas found no breaking changes and no removed/renamed arguments affecting this module — the upgrade is additive/housekeeping only.
- Bumped the `private_endpoint` child module pin from `v1.0.2` to `v1.2.0` (already compatible with `azurerm ~> 5.0`).
- Bumped this module's own `ESLZ/synapse.tf` ref from `v1.1.0` to `v1.2.0`.

### Added

- `synapse.name` — optional override for the auto-generated workspace name (Pattern 12), so existing deployments whose real name diverges from the naming formula can be managed without destroy/recreate.
- `providers.tf`, `.tflint.hcl`, `.gitattributes`, `.github/workflows/release.yml` (previously absent).
- Test coverage for the name override, `firewall_rules`, `customer_managed_key`, `azure_devops_repo`, `github_repo`, `linking_allowed_for_aad_tenant_ids`, `managed_resource_group_name`, `purview_id`, `compute_subnet_id`, `data-lake` map lookup, generated-password path, and the `private_endpoint` sub-module — all previously untested code paths.
- `tflint --recursive` and `tflint --init` steps in `terraform-ci.yml`; verified current action pins (`actions/checkout@v7.0.1`, `hashicorp/setup-terraform@v4.0.1`, `terraform-linters/setup-tflint@v6.3.0`, `terraform-docs/gh-actions@v1.4.1`).

### Fixed

- `.gitignore` was missing a bare `*.tfvars` ignore rule — only `*.tfvars.json` was ignored, so the `!ESLZ/*.tfvars` negation was a no-op and non-ESLZ tfvars files (which may contain secrets) were not excluded from git.
- `azure_devops_repo.tenant_id` and `github_repo.git_url` defaulted to `""` when omitted by the caller. `azurerm 5.0.1` validates both as strict formats (UUID and non-empty URL respectively) even when the block is otherwise valid, so any caller omitting these previously-working optional fields would now fail plan/apply. Both now default to `null` instead.
- `synapse.name` override was only honored by the `azurerm_synapse_workspace` resource itself — the `private_endpoint` child module and the generated `azurerm_key_vault_secret` name still used the raw generated name, so a caller pinning an existing workspace's name would get a private endpoint and KV secret whose names diverge from the actual workspace. Centralized the override into a new `local.synapse-effective-name` (`name.tf`) consumed by all three call sites, with regression test coverage locking in the fix.
- `ESLZ/synapse.tfvars` commented-out `azure_devops_repo`/`customer_managed_key`/`github_repo` examples used list syntax (`[{ ... }]`); the module's `dynamic` blocks iterate over a map (`for_each = try(var.synapse.xxx, {})`), so a caller copying those examples verbatim would hit a type error. Fixed to map form (`{ key = { ... } }`), consistent with the `firewall_rules` example.
- `.github/workflows/release.yml`'s version-extraction regex matched the first `ref=vX.Y.Z` anywhere in `ESLZ/synapse.tf`, which would silently pick the wrong ref if the file ever gains a second versioned reference. Anchored to this module's own source URL.
- `terraform-ci.yml` ran `terraform test` before `tflint`, delaying lint feedback until after the (slower) test suite. Reordered so `tflint` runs immediately after `terraform validate`.
- Documented the rationale for `lifecycle { ignore_changes = [azure_devops_repo, github_repo] }` on `azurerm_synapse_workspace` (Synapse manages repo linking out-of-band via its own API after creation) so it doesn't read as an oversight to future maintainers.

### Known blockers

None.
