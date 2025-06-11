locals {
    resource_group_name = strcontains(var.synapse.resource_group, "/resourceGroups/") ? regex("[^\\/]+$", var.synapse.resource_group) :  var.resource_groups[var.synapse.resource_group].name
    data_lake_id                 = strcontains(var.synapse.data_lake, "https") ? var.synapse.data_lake : var.data-lake[var.synapse.data_lake][keys(var.data-lake[var.synapse.data_lake])[0]]
    sql-admin-password = try(var.synapse.sql_admin_password, "") == "" ?  random_password.sql-admin-password[0].result : try(var.synapse.sql_admin_password, null)
    compute_subnet_id = try(var.synapse.compute_subnet_id, null) == null ? null : strcontains(try(var.synapse.compute_subnet_id, ""), "/resourceGroups/") ? try(var.synapse.compute_subnet_id, null) : var.subnets[var.synapse.compute_subnet_id].id
}