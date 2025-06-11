variable "tags" {
  description = "Tags to be applied to the synapse workspace"
  type = map(string)
  default = {}
}

variable "userDefinedString" {
  description = "(Required) UserDefinedString part of the name of the synapse workspace"
  type = string
}

variable "env" {
  description = "(Required) Env part of the name of the synapse workspace"
  type = string
}

variable "group" {
  description = "(Required) Group part of the name of the synapse workspace"
  type = string
}

variable "project" {
  description = "(Required) Project part of the name of the synapse workspace"
  type = string
}

variable "resource_groups" {
  description = "(Required) List of resource groups in the target project"
  type = any
  default = null
}

variable "location" {
  description = "Azure location where the function will be located"
  type = string
  default = "canadacentral"
}

variable "synapse" {
  description = "Object description all the synapse workspace parameters"
  type = any
  default = {}
}

variable "subnets" {
  description = "Object containing subnet objects of the target project"
  type = any
  default = {}
}

variable "data-lake" {
  description = "List of data lake in the target project"
  type = any
  default = {}
}