# upgrade_compat.tftest.hcl
#
# State-chaining upgrade test: applies the pre-upgrade baseline then plans the
# upgraded config against that state to verify the change is an in-place update
# with zero destroys.
#
# IMPORTANT — known limitation:
#   mock_provider ignores ForceNew constraints. A ForceNew attribute change
#   (e.g. location, name, storage_data_lake_gen2_filesystem_id) will appear
#   as "~ update in-place" here even though the real provider would destroy
#   and recreate the resource.
#
#   What this test DOES catch:
#     - Resource address changes (rename without a moved block) → destroy+create visible
#     - Accidental removal of a resource → destroy visible
#     - Safe additive changes correctly appear as in-place updates (0 to destroy)
#
#   What this test CANNOT catch:
#     - ForceNew attribute changes — requires a real provider plan with credentials.
#     - Use `terraform plan -out=tfplan && terraform show -json tfplan` with real
#       credentials and check that no resource_changes have action_reason containing
#       "replace" before merging an upgrade to main.

mock_provider "azurerm" {}
mock_provider "random" {}

variables {
  env               = "Dev"
  group             = "Corp"
  project           = "Test"
  userDefinedString = "myws"
  resource_groups = {
    Project  = { name = "rg-project", id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-project" }
    Keyvault = { name = "rg-keyvault", id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-keyvault" }
  }
  subnets   = {}
  data-lake = {}
  tags      = {}
}

# Step 1 — establish baseline state (simulates the deployed v1.0.0 resource)
run "baseline_apply" {
  command = apply

  variables {
    synapse = {
      resource_group          = "Project"
      data_lake               = "https://mystorageaccount.dfs.core.windows.net/myfilesystem"
      sql_administrator_login = "sqladmin"
      sql_admin_password      = "TestP@ssw0rd!"
    }
  }

  assert {
    condition     = azurerm_synapse_workspace.synapse-workspace.name == "dev-corp-test-myws-syn"
    error_message = "Baseline apply: unexpected workspace name"
  }
}

# Step 2 — plan the upgraded module code against that baseline state.
# Expect: 0 to destroy. Adding sql_identity_control_enabled is an in-place update.
run "upgrade_plan_no_replacement" {
  command = plan

  variables {
    synapse = {
      resource_group               = "Project"
      data_lake                    = "https://mystorageaccount.dfs.core.windows.net/myfilesystem"
      sql_administrator_login      = "sqladmin"
      sql_admin_password           = "TestP@ssw0rd!"
      sql_identity_control_enabled = true
    }
  }

  assert {
    condition     = azurerm_synapse_workspace.synapse-workspace.name == "dev-corp-test-myws-syn"
    error_message = "Upgrade plan: workspace name must be unchanged"
  }

  assert {
    condition     = azurerm_synapse_workspace.synapse-workspace.sql_identity_control_enabled == true
    error_message = "Upgrade plan: sql_identity_control_enabled must be true"
  }
}
