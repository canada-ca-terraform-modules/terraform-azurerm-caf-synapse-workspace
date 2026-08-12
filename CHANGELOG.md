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

### Known blockers

None.
