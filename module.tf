resource "azurerm_synapse_workspace" "synapse-workspace" {
  name = local.synapse-name
  resource_group_name = local.resource_group_name
  location = var.location
  storage_data_lake_gen2_filesystem_id = local.data_lake_id
  
  sql_administrator_login = try(var.synapse.sql_administrator_login, null)
  sql_administrator_login_password = local.sql-admin-password
  azuread_authentication_only = try(var.synapse.azuread_authentication_only, false)
  compute_subnet_id = local.compute_subnet_id
  data_exfiltration_protection_enabled = try(var.synapse.data_exfiltration_protection_enabled, false)
  linking_allowed_for_aad_tenant_ids = try(var.synapse.linking_allowed_for_aad_tenant_ids, null)
  managed_resource_group_name = try(var.synapse.managed_resource_group_name, null)
  managed_virtual_network_enabled = try(var.synapse.managed_virtual_network_enabled, false)
  public_network_access_enabled = try(var.synapse.public_network_access_enabled, false)
  purview_id = try(var.synapse.purview_id, null)

  tags = merge(var.tags, try(var.synapse.tags, {}))


  dynamic "azure_devops_repo" {
    for_each = try(var.synapse.azure_devops_repo, {})
    content {
      account_name = azure_devops_repo.value.account_name
      branch_name = azure_devops_repo.value.branch_name
      last_commit_id = try(azure_devops_repo.value.last_commit_id, null)
      project_name = azure_devops_repo.value.project_name
      repository_name = azure_devops_repo.value.repository_name
      root_folder = azure_devops_repo.value.root_folder
      tenant_id = try(azure_devops_repo.value.tenant_id, "")
    }
  }

  dynamic "customer_managed_key" {
    for_each = try(var.synapse.customer_managed_key, {})
    content {
      key_versionless_id = customer_managed_key.value.key_versionless_id
      key_name = try(customer_managed_key.value.key_name, null)
      user_assigned_identity_id = try(customer_managed_key.value.user_assigned_identity_id, null)
    }
  }

  dynamic "github_repo" {
    for_each = try(var.synapse.github_repo, {})
    content {
      account_name = azure_devops_repo.value.account_name
      branch_name = azure_devops_repo.value.branch_name
      last_commit_id = try(azure_devops_repo.value.last_commit_id, null)
      repository_name = azure_devops_repo.value.repository_name
      root_folder = azure_devops_repo.value.root_folder
      git_url = try(azure_devops_repo.value.git_url, "")
    }
  }

  dynamic "identity" {
    for_each = try(var.synapse.identity, null) != null ? [1] : []
    content {
      type         = try(var.synapse.identity.type, "SystemAssigned")
      identity_ids = try(var.synapse.identity.identity_ids, [])
    }
  }
}

resource "azurerm_synapse_firewall_rule" "firewall-rules" {
  for_each = try(var.synapse.firewall_rules, {})
  name = each.key
  synapse_workspace_id = azurerm_synapse_workspace.synapse-workspace.id
  start_ip_address = each.value.start_ip_address
  end_ip_address = each.value.end_ip_address
}

# Calls this module if we need a private endpoint attached to the storage account
module "private_endpoint" {
  source = "github.com/canada-ca-terraform-modules/terraform-azurerm-caf-private_endpoint.git?ref=v1.0.2"
  for_each =  try(var.synapse.private_endpoint, {}) 

  name = "${local.synapse-name}-${each.key}"
  location = var.location
  resource_groups = var.resource_groups
  subnets = var.subnets
  private_connection_resource_id = azurerm_synapse_workspace.synapse-workspace.id
  private_endpoint = each.value
  private_dns_zone_ids = null
  tags = var.tags
}