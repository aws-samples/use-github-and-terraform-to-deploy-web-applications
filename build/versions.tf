terraform {
  required_providers {
    aws = {

      source  = "hashicorp/aws"
      version = "~> 5.38.0"

    }
  }
}

provider "aws" {
  region = var.Region

  default_tags {
    tags = {
      Environment = var.EnvTag
      Provisioner = "Terraform"
      Solution    = var.SolTag
    }
  }
}