variable "synapse" {
  default = {}
}

module "synapse-workspace" {
  source = "github.com/canada-ca-terraform-modules/terraform-azurerm-caf-synapse-workspace?ref=v1.0.0"
  for_each = var.synapse

  userDefinedString = each.key
  env = var.env
  group = var.group
  project = var.project
  resource_groups = local.resource_groups_all
  synapse = each.value 
  subnets = local.subnets
  data-lake = local.data_lake_id
  tags = var.tags
}

