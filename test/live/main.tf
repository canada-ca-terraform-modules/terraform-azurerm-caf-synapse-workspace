terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Empty on purpose: the state file path is supplied at `terraform init`
  # time via `-backend-config="path=..."` (partial configuration), so the
  # target-branch checkout and the PR-branch checkout can point at the same
  # external state file without either owning its own local state.
  backend "local" {}
}

provider "azurerm" {
  storage_use_azuread             = true
  resource_provider_registrations = "legacy"
  features {
    resource_group {
      # This harness's resource group is fully self-owned by Terraform - no
      # risk of destroying anything not created by this run.
      prevent_deletion_if_contains_resources = false
    }
  }
}

module "synapse_workspace" {
  # PR code and baseline code are two on-disk checkouts of this same repo,
  # not two resolved git refs - no pinned ?ref, no version toggle here.
  source = "../../"

  userDefinedString = "livetest"
  env               = var.env
  group             = var.group
  project           = var.project
  location          = var.location
  resource_groups   = local.resource_groups # from test_dependencies.tf

  # data_lake is computed (this harness's own throwaway storage account +
  # gen2 filesystem), so it's merged in here rather than living in the
  # static tfvars fixture, which can't reference a resource attribute.
  synapse = merge(var.synapse, {
    resource_group = "Project"
    data_lake      = azurerm_storage_data_lake_gen2_filesystem.live_test.id
  })

  subnets   = {}
  data-lake = {}
  tags      = var.tags
}
