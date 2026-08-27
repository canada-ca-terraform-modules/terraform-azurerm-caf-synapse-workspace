# config/synapse_workspace.tfvars
# Tracked, ready-to-run fixture for the test/live harness - one representative
# real-usage instance, not a two-code-path engineered fixture and not a
# dormant "_" template.
#
# sql_admin_password is set explicitly (not left to auto-generate) so this
# harness never needs a real Key Vault: the module's secret.tf only looks
# up/creates a Key Vault secret when try(var.synapse.sql_admin_password, "") == "".
#
# identity and public_network_access_enabled are set explicitly to work
# around real Azure API validation that fails regardless of azurerm provider
# version when left at the module's own defaults (identity omitted,
# public_network_access_enabled defaulting to false with no managed VNet):
#   - "SystemAssignedManagedIdentityNotSpecified" - Synapse requires an
#     identity block on workspace creation.
#   - "PublicNetworkAccessSettingsOnlyApplicableForManagedVnet" -
#     public_network_access_enabled = false is only valid when
#     managed_virtual_network_enabled = true.
#
# resource_group and data_lake are intentionally omitted here - main.tf
# merges them in from this harness's own test_dependencies.tf resources,
# since a static tfvars file can't reference a resource attribute.

synapse = {
  sql_administrator_login       = "synapseadmin"
  sql_admin_password            = "CHANGE-ME-set-a-real-password-before-first-apply"
  public_network_access_enabled = true
  identity = {
    type = "SystemAssigned"
  }
}
