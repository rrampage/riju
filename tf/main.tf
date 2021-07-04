terraform {
  backend "s3" {
    key    = "state"
    region = "us-west-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.45"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.1"
    }
  }
}

data "external" "env" {
  program = ["jq", "-n", "env"]
}

locals {
  tags = {
    Terraform       = "Managed by Terraform"
    BillingCategory = "Riju"
  }

  ami_available = lookup(data.external.env.result, "AMI_NAME", "") != "" ? true : false
}

provider "aws" {
  region = "us-west-1"
  default_tags {
    tags = local.tags
  }
}

data "aws_region" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_subnet" "default" {
  for_each = data.aws_subnet_ids.default.ids
  id = each.value
}
