locals {
  project      = "endpoint"
  publicSubnet = "0" #the subnet that we would like to provision our elastic beanstalk instances on
}

#protip: don't flippin' do this.  Put your states in an s3 bucket.
#"Why you doin' it in an interview, dan?" cuz it's expedient. :)
data "terraform_remote_state" "baseInfra" {
  backend = "local"

  config = {
    path = "../baseInfra/terraform.tfstate"
  }
}

data "aws_caller_identity" "current" {}

provider "aws" {
  region = "us-west-2"

  default_tags {
    tags = {
      Project        = local.project
      tfService      = "application"
      "Service Name" = "postgres application stack"
    }
  }
}
