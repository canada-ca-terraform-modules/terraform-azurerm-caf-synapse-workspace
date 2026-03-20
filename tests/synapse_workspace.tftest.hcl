mock_provider "azurerm" {}
mock_provider "random" {}

# Shared variables reused across all runs.
# sql_admin_password is set to bypass the azurerm_key_vault data source (count = 0 when password is provided).
# resource_groups["Keyvault"] must always be present — kv_sha is an unconditional local in secret.tf.
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

run "naming_convention" {
  command = plan

  variables {
    synapse = {
      resource_group          = "Project"
      data_lake               = "https://mystorageaccount.dfs.core.windows.net/myfilesystem"
      sql_administrator_login = "sqladmin"
      sql_admin_password      = "TestP@ssw0rd!"
    }
  }

  # env="Dev" → "dev", group="Corp" → "corp", project="Test" → "test", userDefinedString="myws" → "myws"
  assert {
    condition     = azurerm_synapse_workspace.synapse-workspace.name == "dev-corp-test-myws-syn"
    error_message = "Name must follow {env}-{group}-{project}-{userDefinedString}-syn convention (lowercased, non-alphanumeric stripped)"
  }
}

run "default_values" {
  command = plan

  variables {
    synapse = {
      resource_group          = "Project"
      data_lake               = "https://mystorageaccount.dfs.core.windows.net/myfilesystem"
      sql_administrator_login = "sqladmin"
      sql_admin_password      = "TestP@ssw0rd!"
    }
  }

  assert {
    condition     = azurerm_synapse_workspace.synapse-workspace.azuread_authentication_only == false
    error_message = "azuread_authentication_only must default to false"
  }

  assert {
    condition     = azurerm_synapse_workspace.synapse-workspace.managed_virtual_network_enabled == false
    error_message = "managed_virtual_network_enabled must default to false"
  }

  assert {
    condition     = azurerm_synapse_workspace.synapse-workspace.data_exfiltration_protection_enabled == false
    error_message = "data_exfiltration_protection_enabled must default to false"
  }
}

run "public_network_disabled" {
  command = plan

  variables {
    synapse = {
      resource_group                = "Project"
      data_lake                     = "https://mystorageaccount.dfs.core.windows.net/myfilesystem"
      sql_administrator_login       = "sqladmin"
      sql_admin_password            = "TestP@ssw0rd!"
      public_network_access_enabled = false
    }
  }

  assert {
    condition     = azurerm_synapse_workspace.synapse-workspace.public_network_access_enabled == false
    error_message = "public_network_access_enabled must be false"
  }
}

run "azuread_only_auth" {
  command = plan

  variables {
    synapse = {
      resource_group              = "Project"
      data_lake                   = "https://mystorageaccount.dfs.core.windows.net/myfilesystem"
      sql_admin_password          = "TestP@ssw0rd!"
      azuread_authentication_only = true
    }
  }

  assert {
    condition     = azurerm_synapse_workspace.synapse-workspace.azuread_authentication_only == true
    error_message = "azuread_authentication_only must be true"
  }
}

run "sql_identity_control_enabled" {
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
    condition     = azurerm_synapse_workspace.synapse-workspace.sql_identity_control_enabled == true
    error_message = "sql_identity_control_enabled must be true"
  }
}

run "with_system_assigned_identity" {
  command = plan

  variables {
    synapse = {
      resource_group          = "Project"
      data_lake               = "https://mystorageaccount.dfs.core.windows.net/myfilesystem"
      sql_administrator_login = "sqladmin"
      sql_admin_password      = "TestP@ssw0rd!"
      identity = {
        type         = "SystemAssigned"
        identity_ids = []
      }
    }
  }

  assert {
    condition     = length(azurerm_synapse_workspace.synapse-workspace.identity) == 1
    error_message = "identity block must be present when identity is configured"
  }
}

run "managed_vnet_with_exfiltration_protection" {
  command = plan

  variables {
    synapse = {
      resource_group                       = "Project"
      data_lake                            = "https://mystorageaccount.dfs.core.windows.net/myfilesystem"
      sql_administrator_login              = "sqladmin"
      sql_admin_password                   = "TestP@ssw0rd!"
      managed_virtual_network_enabled      = true
      data_exfiltration_protection_enabled = true
    }
  }

  assert {
    condition     = azurerm_synapse_workspace.synapse-workspace.managed_virtual_network_enabled == true
    error_message = "managed_virtual_network_enabled must be true"
  }

  assert {
    condition     = azurerm_synapse_workspace.synapse-workspace.data_exfiltration_protection_enabled == true
    error_message = "data_exfiltration_protection_enabled must be true"
  }
}

run "resource_group_as_full_id" {
  command = plan

  # Validates the strcontains(/.../resourceGroups/...) path in locals.tf
  variables {
    synapse = {
      resource_group          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-direct"
      data_lake               = "https://mystorageaccount.dfs.core.windows.net/myfilesystem"
      sql_administrator_login = "sqladmin"
      sql_admin_password      = "TestP@ssw0rd!"
    }
  }

  assert {
    condition     = azurerm_synapse_workspace.synapse-workspace.resource_group_name == "rg-direct"
    error_message = "resource_group_name must be extracted from full ARM ID when a full ID is passed"
  }
}
