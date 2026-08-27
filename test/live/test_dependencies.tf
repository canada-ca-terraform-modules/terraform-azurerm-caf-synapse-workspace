# test_dependencies.tf
# Self-contained dependency resources, owned entirely by this harness.
#
# Deliberately NOT reusing any shared/production resource group or storage
# account: writing into a shared RG usually requires elevated, non-sandbox
# permissions. A dedicated throwaway RG (+ storage account + gen2
# filesystem) here needs only Contributor on the sandbox subscription and
# can never collide with or affect any production resource.
#
# terraform-azurerm-caf-synapse-workspace requires a real, existing ADLS
# Gen2 filesystem ID for storage_data_lake_gen2_filesystem_id (Required,
# ForceNew) - this harness creates its own rather than depending on any
# shared storage account.

resource "azurerm_resource_group" "live_test" {
  # PR-number suffix keeps two concurrently open PRs against this module from
  # colliding on the same sandbox resource group (or, via the module's own
  # resource_group.id-derived naming, the same synapse workspace name).
  name     = "${var.env}-caf-synapse-workspace-live-test-${var.pr_number}-rg"
  location = var.location

  # pr-number tag: lets the nightly orphan sweeper find this RG by tag and
  # match it back to a PR, independent of naming convention.
  # repository tag: the sandbox subscription is shared across module repos,
  # so the sweeper must scope its `pr-number` matches to only this repo's
  # own PRs - otherwise a PR number collision across repos could
  # misclassify (or destroy) another repo's live resource group.
  tags = {
    "pr-number"  = var.pr_number
    "repository" = var.repository
  }
}

resource "random_string" "sa_suffix" {
  length  = 6
  special = false
  upper   = false
  numeric = true
}

resource "azurerm_storage_account" "live_test" {
  name                     = "syntest${random_string.sa_suffix.result}"
  resource_group_name      = azurerm_resource_group.live_test.name
  location                 = azurerm_resource_group.live_test.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
}

resource "azurerm_storage_data_lake_gen2_filesystem" "live_test" {
  name               = "livetest"
  storage_account_id = azurerm_storage_account.live_test.id
}

locals {
  resource_groups = {
    Project = {
      name = azurerm_resource_group.live_test.name
      id   = azurerm_resource_group.live_test.id
    }
    # Dummy entry - terraform-azurerm-caf-synapse-workspace's secret.tf
    # unconditionally computes kv_sha = substr(sha1(var.resource_groups["Keyvault"].id), 0, 8)
    # as an eagerly-evaluated local regardless of whether the KV secret
    # resource itself gets created. This harness always supplies
    # synapse.sql_admin_password explicitly (see config/synapse_workspace.tfvars),
    # so that resource's count is 0 and no real Key Vault is ever looked up or
    # written to - but the map key must still resolve to something with an
    # .id attribute or the plan fails on the eager local evaluation alone.
    Keyvault = {
      name = azurerm_resource_group.live_test.name
      id   = azurerm_resource_group.live_test.id
    }
  }
}
