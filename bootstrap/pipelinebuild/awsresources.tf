### Create AWS resources for Terraform bootstrapping across multiple accounts
module "tfbootstrap_dev" {
  source = "./modules/tfbootstrap"
  providers = {
    aws = aws.development
  }
  Region     = var.Region
  Prefix     = var.Prefix
  EnvCode    = "dv"
  GitHubOrg  = var.GitHubOrg
  GitHubRepo = var.GitHubRepo
  GitHubEnv  = "dev"
}

module "tfbootstrap_test" {
  source = "./modules/tfbootstrap"
  providers = {
    aws = aws.testing
  }
  Region     = var.Region
  Prefix     = var.Prefix
  EnvCode    = "ts"
  GitHubOrg  = var.GitHubOrg
  GitHubRepo = var.GitHubRepo
  GitHubEnv  = "test"
}

module "tfbootstrap_prod" {
  source = "./modules/tfbootstrap"
  providers = {
    aws = aws.production
  }
  Region     = var.Region
  Prefix     = var.Prefix
  EnvCode    = "pd"
  GitHubOrg  = var.GitHubOrg
  GitHubRepo = var.GitHubRepo
  GitHubEnv  = "prod"
}

# DEBUGGING: Outputs for GitHub Action Secrets
# output "gha_iam_role" {
#   value = {
#     dev  = module.tfbootstrap_dev.gha_iam_role
#     test = module.tfbootstrap_test.gha_iam_role
#     prod = module.tfbootstrap_prod.gha_iam_role
#   }
# }

# output "tfstate_bucket_names" {
#   value = {
#     dev  = module.tfbootstrap_dev.tfstate_bucket_name
#     test = module.tfbootstrap_test.tfstate_bucket_name
#     prod = module.tfbootstrap_prod.tfstate_bucket_name
#   }
# }

# output "tfstate_dynamodb_table" {
#   value = {
#     dev  = module.tfbootstrap_dev.tfstate_dynamodb_table_name
#     test = module.tfbootstrap_test.tfstate_dynamodb_table_name
#     prod = module.tfbootstrap_prod.tfstate_dynamodb_table_name
#   }
# }