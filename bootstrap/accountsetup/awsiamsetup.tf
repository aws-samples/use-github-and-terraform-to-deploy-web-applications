### Create IAM policies required to bootstrap Terraform across multiple accounts
data "aws_caller_identity" "primary" {
  provider = aws.primary
}

data "aws_caller_identity" "development" {
  provider = aws.development
}

data "aws_caller_identity" "testing" {
  provider = aws.testing
}

data "aws_caller_identity" "production" {
  provider = aws.production
}

module "assumerole_dev" {
  source = "./modules/assumerole"
  providers = {
    aws = aws.development
  }
  Region        = var.Region
  Prefix        = var.Prefix
  Environment   = "dv"
  PrimaryAccount = data.aws_caller_identity.primary.arn
  TargetAccount = data.aws_caller_identity.development.account_id
}

module "assumerole_test" {
  source = "./modules/assumerole"
  providers = {
    aws = aws.testing
  }
  Region        = var.Region
  Prefix        = var.Prefix
  Environment   = "ts"
  PrimaryAccount = data.aws_caller_identity.primary.arn
  TargetAccount = data.aws_caller_identity.testing.account_id
}

module "assumerole_prod" {
  source = "./modules/assumerole"
  providers = {
    aws = aws.production
  }
  Region        = var.Region
  Prefix        = var.Prefix
  Environment   = "pd"
  PrimaryAccount = data.aws_caller_identity.primary.arn
  TargetAccount = data.aws_caller_identity.production.account_id
}

output "role_arn" {
  value = {
    dev_role_arn  = module.assumerole_dev.role_arn
    test_role_arn = module.assumerole_test.role_arn
    prod_role_arn = module.assumerole_prod.role_arn
  }
}