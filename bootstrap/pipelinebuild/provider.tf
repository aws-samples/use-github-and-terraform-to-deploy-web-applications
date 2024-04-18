terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0.0"
    }
  }
}

provider "github" {
  owner = "<FILLMEIN>"
}

provider "aws" {
  alias   = "development"
  profile = "default"
  region  = var.Region

  assume_role {

    role_arn = var.dev_role_arn
  }
  default_tags {
    tags = {
      Environment = "Development"
      Provisioner = "Terraform"
      Solution    = "AWS-GHA-TF-MSFT"
    }
  }
}

provider "aws" {
  alias   = "testing"
  profile = "default"
  region  = var.Region

  assume_role {
    role_arn = var.test_role_arn
  }
  default_tags {
    tags = {
      Environment = "Testing"
      Provisioner = "Terraform"
    }
  }
}

provider "aws" {
  alias   = "production"
  profile = "default"
  region  = var.Region

  assume_role {
    role_arn = var.prod_role_arn
  }

  default_tags {
    tags = {
      Environment = "Production"
      Provisioner = "Terraform"
    }
  }
}