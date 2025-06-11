locals {
  # anti-pattern-regex = "/[//\"'\\[\\]:|<>+=;,?*@&]/"
  # synapse-name = replace("${var.env}-${var.group}-${var.project}-${var.userDefinedString}-syn", local.anti-pattern-regex, "")

  synapse-regex                                = "/[^0-9a-z]/" # Anti-pattern to match all characters not in: 0-9 a-z
  env-regex_compliant_4                        = replace(lower(var.env), local.synapse-regex, "")
  group-regex_compliant_4                      = replace(lower(var.group), local.synapse-regex, "")
  project-regex_compliant_4                    = replace(lower(var.project), local.synapse-regex, "")
  synapse-userDefinedString-regex_compliant_16 = replace(lower(var.userDefinedString), local.synapse-regex, "")
  synapse-name                                 = "${local.env-regex_compliant_4}-${local.group-regex_compliant_4}-${local.project-regex_compliant_4}-${local.synapse-userDefinedString-regex_compliant_16}-syn"
}
