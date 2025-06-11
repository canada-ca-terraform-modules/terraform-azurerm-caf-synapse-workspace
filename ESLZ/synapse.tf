variable "synapse" {
  default = {}
}

module "synapse-workspace" {
  source = "/home/max/devops/modules/terraform-azurerm-caf-synapse_workspace"
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

