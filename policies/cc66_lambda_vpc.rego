package compliance.cc66_lambda_vpc

import rego.v1

deny contains msg if {
  some resource in input.configuration.root_module.resources
  resource.type == "aws_lambda_function"
  not has_vpc_config(resource)
  msg := sprintf(
    "[AC-3/CC6.6] %s: Lambda not deployed in a VPC. Remediation: add vpc_config with subnet_ids and security_group_ids.",
    [resource.address],
  )
}

has_vpc_config(resource) if {
  resource.expressions.vpc_config[_].subnet_ids
}