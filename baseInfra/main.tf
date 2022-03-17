#NOTE if converted to a vpc module, this should become a set of variables instead of locals
locals {
  project = "endpoint"
  cidr    = "172.16.0.0/16"
  publicSubnets = { #NOTE this assumes each subnet is effectively an man-specified object.  Dynamic subnetting sucks. Use a map, don't trust tf ordering.
    0 = {
      cidr = "172.16.1.0/24"
      az   = "us-west-2a"
    }
  }

}

provider "aws" {
  region = "us-west-2"

  #NOTE This is where I'd put an `assume_role` if we were doing ci/cd

  default_tags {
    tags = {
      Project        = local.project
      tfService      = "baseInfra"
      "Service Name" = "${local.project} main infrastructure"
    }
  }
}
