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

run "name_override" {
  command = plan

  # Pattern 12: optional override for the auto-generated workspace name
  variables {
    synapse = {
      name                    = "existing-prod-synapse"
      resource_group          = "Project"
      data_lake               = "https://mystorageaccount.dfs.core.windows.net/myfilesystem"
      sql_administrator_login = "sqladmin"
      sql_admin_password      = "TestP@ssw0rd!"
    }
  }

  assert {
    condition     = azurerm_synapse_workspace.synapse-workspace.name == "existing-prod-synapse"
    error_message = "synapse.name override must take priority over the generated name"
  }
}

run "firewall_rules" {
  command = plan

  variables {
    synapse = {
      resource_group          = "Project"
      data_lake               = "https://mystorageaccount.dfs.core.windows.net/myfilesystem"
      sql_administrator_login = "sqladmin"
      sql_admin_password      = "TestP@ssw0rd!"
      firewall_rules = {
        AllowAll = {
          start_ip_address = "0.0.0.0"
          end_ip_address   = "255.255.255.255"
        }
      }
    }
  }

  assert {
    condition     = azurerm_synapse_firewall_rule.firewall-rules["AllowAll"].start_ip_address == "0.0.0.0"
    error_message = "firewall_rules must create a matching azurerm_synapse_firewall_rule"
  }

  assert {
    condition     = azurerm_synapse_firewall_rule.firewall-rules["AllowAll"].end_ip_address == "255.255.255.255"
    error_message = "firewall_rules end_ip_address must match"
  }
}

run "customer_managed_key" {
  command = plan

  variables {
    synapse = {
      resource_group          = "Project"
      data_lake               = "https://mystorageaccount.dfs.core.windows.net/myfilesystem"
      sql_administrator_login = "sqladmin"
      sql_admin_password      = "TestP@ssw0rd!"
      customer_managed_key = {
        cmk1 = {
          key_versionless_id = "https://example-keyvault.vault.azure.net/keys/enckey"
        }
      }
    }
  }

  assert {
    condition     = azurerm_synapse_workspace.synapse-workspace.customer_managed_key[0].key_versionless_id == "https://example-keyvault.vault.azure.net/keys/enckey"
    error_message = "customer_managed_key block must be rendered from the synapse.customer_managed_key map"
  }
}

run "azure_devops_repo" {
  command = plan

  variables {
    synapse = {
      resource_group          = "Project"
      data_lake               = "https://mystorageaccount.dfs.core.windows.net/myfilesystem"
      sql_administrator_login = "sqladmin"
      sql_admin_password      = "TestP@ssw0rd!"
      azure_devops_repo = {
        repo1 = {
          account_name    = "myaccount"
          branch_name     = "main"
          project_name    = "myproject"
          repository_name = "myrepo"
          root_folder     = "/"
        }
      }
    }
  }

  assert {
    condition     = azurerm_synapse_workspace.synapse-workspace.azure_devops_repo[0].account_name == "myaccount"
    error_message = "azure_devops_repo block must be rendered from the synapse.azure_devops_repo map"
  }
}

run "github_repo" {
  command = plan

  variables {
    synapse = {
      resource_group          = "Project"
      data_lake               = "https://mystorageaccount.dfs.core.windows.net/myfilesystem"
      sql_administrator_login = "sqladmin"
      sql_admin_password      = "TestP@ssw0rd!"
      github_repo = {
        repo1 = {
          account_name    = "myaccount"
          branch_name     = "main"
          repository_name = "myrepo"
          root_folder     = "/"
        }
      }
    }
  }

  assert {
    condition     = azurerm_synapse_workspace.synapse-workspace.github_repo[0].account_name == "myaccount"
    error_message = "github_repo block must be rendered from the synapse.github_repo map"
  }
}

run "linking_managed_rg_and_purview" {
  command = plan

  variables {
    synapse = {
      resource_group                     = "Project"
      data_lake                          = "https://mystorageaccount.dfs.core.windows.net/myfilesystem"
      sql_administrator_login            = "sqladmin"
      sql_admin_password                 = "TestP@ssw0rd!"
      linking_allowed_for_aad_tenant_ids = ["00000000-0000-0000-0000-000000000000"]
      managed_resource_group_name        = "rg-synapse-managed"
      purview_id                         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Purview/accounts/mypurview"
    }
  }

  assert {
    condition     = tolist(azurerm_synapse_workspace.synapse-workspace.linking_allowed_for_aad_tenant_ids)[0] == "00000000-0000-0000-0000-000000000000"
    error_message = "linking_allowed_for_aad_tenant_ids must be passed through"
  }

  assert {
    condition     = azurerm_synapse_workspace.synapse-workspace.managed_resource_group_name == "rg-synapse-managed"
    error_message = "managed_resource_group_name must be passed through"
  }

  assert {
    condition     = azurerm_synapse_workspace.synapse-workspace.purview_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Purview/accounts/mypurview"
    error_message = "purview_id must be passed through"
  }
}

run "compute_subnet_id_full_arm_id" {
  command = plan

  variables {
    synapse = {
      resource_group          = "Project"
      data_lake               = "https://mystorageaccount.dfs.core.windows.net/myfilesystem"
      sql_administrator_login = "sqladmin"
      sql_admin_password      = "TestP@ssw0rd!"
      compute_subnet_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/compute"
    }
  }

  assert {
    condition     = azurerm_synapse_workspace.synapse-workspace.compute_subnet_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/compute"
    error_message = "compute_subnet_id must pass a full ARM ID through unchanged"
  }
}

run "compute_subnet_id_from_subnet_map" {
  command = plan

  variables {
    subnets = {
      OZ = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/oz-subnet" }
    }
    synapse = {
      resource_group          = "Project"
      data_lake               = "https://mystorageaccount.dfs.core.windows.net/myfilesystem"
      sql_administrator_login = "sqladmin"
      sql_admin_password      = "TestP@ssw0rd!"
      compute_subnet_id       = "OZ"
    }
  }

  assert {
    condition     = azurerm_synapse_workspace.synapse-workspace.compute_subnet_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/oz-subnet"
    error_message = "compute_subnet_id must be resolved from var.subnets by key when not a full ARM ID"
  }
}

run "data_lake_from_map_lookup" {
  command = plan

  variables {
    data-lake = {
      mydl = { myfs = "https://mystorageaccount.dfs.core.windows.net/myfilesystem" }
    }
    synapse = {
      resource_group          = "Project"
      data_lake               = "mydl"
      sql_administrator_login = "sqladmin"
      sql_admin_password      = "TestP@ssw0rd!"
    }
  }

  assert {
    condition     = azurerm_synapse_workspace.synapse-workspace.storage_data_lake_gen2_filesystem_id == "https://mystorageaccount.dfs.core.windows.net/myfilesystem"
    error_message = "data_lake must be resolved from var.data-lake by key when it is not an https URL"
  }
}

run "with_private_endpoint" {
  command = plan

  # Runs before any apply-based run in this file so the synapse workspace's id
  # is still unresolved ("known after apply") rather than a leftover concrete
  # value from shared file state — the private_endpoint child module validates
  # private_connection_resource_id as a real Azure resource ID, so a concrete
  # mock_provider-generated random string would otherwise fail that check.
  variables {
    subnets = {
      OZ = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/oz-subnet" }
    }
    synapse = {
      resource_group          = "Project"
      data_lake               = "https://mystorageaccount.dfs.core.windows.net/myfilesystem"
      sql_administrator_login = "sqladmin"
      sql_admin_password      = "TestP@ssw0rd!"
      private_endpoint = {
        blob = {
          resource_group    = "Project"
          subnet            = "OZ"
          subresource_names = ["sql"]
        }
      }
    }
  }

  assert {
    condition     = length(module.private_endpoint) == 1
    error_message = "private_endpoint map must create one private_endpoint module instance per key"
  }
}

run "generated_password_when_omitted" {
  command = apply

  override_data {
    target = data.azurerm_key_vault.key_vault[0]
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-keyvault/providers/Microsoft.KeyVault/vaults/kv-test"
    }
  }

  variables {
    synapse = {
      resource_group          = "Project"
      data_lake               = "https://mystorageaccount.dfs.core.windows.net/myfilesystem"
      sql_administrator_login = "sqladmin"
    }
  }

  assert {
    condition     = length(random_password.sql-admin-password) == 1
    error_message = "A random password must be generated when sql_admin_password is omitted"
  }

  assert {
    condition     = length(azurerm_key_vault_secret.sql-admin-password) == 1
    error_message = "The generated password must be stored in the subscription key vault"
  }
}
