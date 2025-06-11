synapse = {
  name = {
    resource_group                = "Project"
    data_lake                     = "data_lake"
    sql_administrator_login       = "azureadmin"
    public_network_access_enabled = false
    
    # Optional parameters
    # azuread_authentication_only          = false
    # compute_subnet_id                    = ""
    # data_exfiltration_protection_enabled = false
    # linking_allowed_for_aad_tenant_ids   = ""
    # managed_resource_group_name          = ""
    # managed_virtual_network_enabled      = false
    # public_network_access_enabled        = false
    # purview_id                           = ""

    # Optional
    # azure_devops_repo = [{
    #   account_name = ""
    #   branch_name = ""
    #   last_commit_id = ""
    #   project_name = ""
    #   repository_name = ""
    #   root_folder = ""
    #   tenant_id = ""
    # }]

    # Optional
    # customer_managed_key = [{
    #   key_versionless_id = ""
    #   key_name = ""
    #   user_assigned_identity_id = ""
    # }]

    # Optional
    # github_repo = [{
    #   account_name = ""
    #   branch_name = ""
    #   last_commit_id = ""
    #   repository_name = ""
    #   root_folder = ""
    #   git_url = ""
    # }]

    # Optional
    # firewall_rules = {
    #   rule1 = {
    #     start_ip_address = ""
    #     end_ip_address = ""
    #   }
    # }

    # identity = {
    #   type = "SystemAssigned"
    #   identity_ids = []
    # }

    private_endpoint = {
      blob = {                        # Key defines the userDefinedstring
        resource_group    = "Project" # Required: Resource group name, i.e Project, Management, DNS, etc, or the resource group ID
        subnet            = "OZ"      # Required: Subnet name, i.e OZ,MAZ, etc, or the subnet ID
        subresource_names = ["sql"]   # Required: Subresource name determines to what service the private endpoint will connect to. see: https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview#private-link-resource for list of subresrouce
        # local_dns_zone    = "privatelink.blob.core.windows.net" # Optional: Name of the local DNS zone for the private endpoint
      }
    }
  }
}
