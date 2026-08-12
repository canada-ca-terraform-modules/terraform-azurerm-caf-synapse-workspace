<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 5.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 5.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_private_endpoint"></a> [private\_endpoint](#module\_private\_endpoint) | github.com/canada-ca-terraform-modules/terraform-azurerm-caf-private_endpoint.git | v1.2.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault_secret.sql-admin-password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_synapse_firewall_rule.firewall-rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/synapse_firewall_rule) | resource |
| [azurerm_synapse_workspace.synapse-workspace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/synapse_workspace) | resource |
| [random_password.sql-admin-password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [azurerm_key_vault.key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_data-lake"></a> [data-lake](#input\_data-lake) | List of data lake in the target project | `any` | `{}` | no |
| <a name="input_env"></a> [env](#input\_env) | (Required) Env part of the name of the synapse workspace | `string` | n/a | yes |
| <a name="input_group"></a> [group](#input\_group) | (Required) Group part of the name of the synapse workspace | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure location where the function will be located | `string` | `"canadacentral"` | no |
| <a name="input_project"></a> [project](#input\_project) | (Required) Project part of the name of the synapse workspace | `string` | n/a | yes |
| <a name="input_resource_groups"></a> [resource\_groups](#input\_resource\_groups) | (Required) List of resource groups in the target project | `any` | `null` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Object containing subnet objects of the target project | `any` | `{}` | no |
| <a name="input_synapse"></a> [synapse](#input\_synapse) | Object description all the synapse workspace parameters | `any` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to be applied to the synapse workspace | `map(string)` | `{}` | no |
| <a name="input_userDefinedString"></a> [userDefinedString](#input\_userDefinedString) | (Required) UserDefinedString part of the name of the synapse workspace | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_synapse-workspace-id"></a> [synapse-workspace-id](#output\_synapse-workspace-id) | Returns the ID of the synapse workspace |
| <a name="output_synapse-workspace-name"></a> [synapse-workspace-name](#output\_synapse-workspace-name) | Returns the name of the synapse workspace |
| <a name="output_synapse-workspace-object"></a> [synapse-workspace-object](#output\_synapse-workspace-object) | Returns the Synapse workspace object |
<!-- END_TF_DOCS -->
