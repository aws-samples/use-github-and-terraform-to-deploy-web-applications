### Create GitHub pipeline resources

# Create GitHub branch per environment. Existing Main branch is used for prod
resource "github_branch" "dev" {
  repository = var.GitHubRepo
  branch     = "dev"
}

resource "github_branch" "test" {
  repository = var.GitHubRepo
  branch     = "test"
}

# Local variables used to define GitHub Environments and Secrets configuration
locals {
  gha_environment = ["dev", "test", "prod"]

  gha_iam_role = {
    dev  = module.tfbootstrap_dev.gha_iam_role
    test = module.tfbootstrap_test.gha_iam_role
    prod = module.tfbootstrap_prod.gha_iam_role
  }
  tfstate_bucket_name = {
    dev  = module.tfbootstrap_dev.tfstate_bucket_name
    test = module.tfbootstrap_test.tfstate_bucket_name
    prod = module.tfbootstrap_prod.tfstate_bucket_name
  }
  tfstate_dynamodb_table = {
    dev  = module.tfbootstrap_dev.tfstate_dynamodb_table_name
    test = module.tfbootstrap_test.tfstate_dynamodb_table_name
    prod = module.tfbootstrap_prod.tfstate_dynamodb_table_name
  }
}

# Create GitHub Environments
resource "github_repository_environment" "env" {
  for_each = toset(local.gha_environment)

  environment = each.value
  repository  = var.GitHubRepo

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

# Create GitHub environment branch policies
resource "github_repository_environment_deployment_policy" "dev" {
  repository     = var.GitHubRepo
  environment    = github_repository_environment.env["dev"].environment
  branch_pattern = "dev*"
}

resource "github_repository_environment_deployment_policy" "dev2test" {
  repository     = var.GitHubRepo
  environment    = github_repository_environment.env["test"].environment
  branch_pattern = "dev*"
}

resource "github_repository_environment_deployment_policy" "test" {
  repository     = var.GitHubRepo
  environment    = github_repository_environment.env["test"].environment
  branch_pattern = "test*"
}

resource "github_repository_environment_deployment_policy" "test2prod" {
  repository     = var.GitHubRepo
  environment    = github_repository_environment.env["prod"].environment
  branch_pattern = "test*"
}

resource "github_repository_environment_deployment_policy" "prod" {
  repository     = var.GitHubRepo
  environment    = github_repository_environment.env["prod"].environment
  branch_pattern = "main"
}

# Create GitHub branch protection policy
resource "github_branch_protection" "main" {
  repository_id          = var.GitHubRepo
  pattern                = "main"
  require_signed_commits = true

  required_pull_request_reviews {
    required_approving_review_count = 2
    require_code_owner_reviews      = true
  }
}

### Create GitHub Environment Secrets

# IAM Role ARN used by GitHub Actions runner to deploy AWS resources
resource "github_actions_environment_secret" "AWS_ROLE" {
  for_each = github_repository_environment.env

  repository      = var.GitHubRepo
  environment     = each.value.environment
  secret_name     = "AWS_ROLE"
  plaintext_value = lookup(local.gha_iam_role, each.value.environment, null)
}

# Terraform state S3 bucket name
resource "github_actions_environment_secret" "TF_STATE_BUCKET_NAME" {
  for_each = github_repository_environment.env

  repository      = var.GitHubRepo
  environment     = each.value.environment
  secret_name     = "TF_STATE_BUCKET_NAME"
  plaintext_value = lookup(local.tfstate_bucket_name, each.value.environment, null)
}

# Terraform state S3 bucket key
resource "github_actions_environment_secret" "TF_STATE_BUCKET_KEY" {
  for_each = github_repository_environment.env

  repository      = var.GitHubRepo
  environment     = each.value.environment
  secret_name     = "TF_STATE_BUCKET_KEY"
  plaintext_value = "terraform/${each.value.environment}.tfstate"
}

# Terraform state locking DynamoDB table
resource "github_actions_environment_secret" "TF_STATE_DYNAMODB_TABLE" {
  for_each = github_repository_environment.env

  repository      = var.GitHubRepo
  environment     = each.value.environment
  secret_name     = "TF_STATE_DYNAMODB_TABLE"
  plaintext_value = lookup(local.tfstate_dynamodb_table, each.value.environment, null)
}

# Infracost API Key
resource "github_actions_environment_secret" "INFRACOST_API_KEY" {

  repository      = var.GitHubRepo
  environment     = "test"
  secret_name     = "INFRACOST_API_KEY"
  plaintext_value = var.InfraCostAPIKey

  depends_on = [github_repository_environment.env]
}

### Create GitHub Environment Variables

# Locals used for constructing GitHub Variables
locals {
  # Declare GitHub Environments variables
  environment_variables_common = {
    # Deployment region e.g. eu-west-1
    TF_VAR_REGION     = "<FILLMEIN>"
    # Deployment Availability Zone 1 e.g. eu-west-1a
    TF_VAR_AZ01       = "<FILLMEIN>"
    # Deployment Availability Zone 2 e.g. eu-west-1b
    TF_VAR_AZ02       = "<FILLMEIN>"
    # The Public IP address from which the web application will be accessed e.g. x.x.x.x/32
    TF_VAR_PUBLICIP   = "<FILLMEIN>"
    # A prefix appended to the name of all AWS-created resources e.g. ghablog WARNING: use lowercase character only and no symbols
    TF_VAR_PREFIX     = "<FILLMEIN>"
    TF_VAR_SOLTAG     = "AWS-GHA-TF-MSFT"
    TF_VAR_GITHUBREPO = format("%s%s%s", var.GitHubOrg, "/", var.GitHubRepo)
    # The first two octets of the CIDR IP address range e.g. 10.0
    TF_VAR_VPCCIDR    = "<FILLMEIN>"
    TF_VAR_ECRREPO    = "mswebapp"
    TF_VAR_IMAGETAG   = "1.0.0"
  }
  # Declare dev specific GitHub Environments variables
  environment_variables_dev = merge(
    local.environment_variables_common,
    {
      TF_VAR_ENVCODE = "dv"
      TF_VAR_ENVTAG  = "Development"
    }
  )
  # Declare test specific GitHub Environments variables
  environment_variables_test = merge(
    local.environment_variables_common,
    {
      TF_VAR_ENVCODE = "ts"
      TF_VAR_ENVTAG  = "Testing"
    }
  )
  # Declare prod specific GitHub Environments variables
  environment_variables_prod = merge(
    local.environment_variables_common,
    {
      TF_VAR_ENVCODE = "pd"
      TF_VAR_ENVTAG  = "Production"
    }
  )
}

# Create GitHub Environment Variables
resource "github_actions_environment_variable" "dev" {
  for_each = local.environment_variables_dev

  repository    = var.GitHubRepo
  environment   = github_repository_environment.env["dev"].environment
  variable_name = each.key
  value         = each.value
}

resource "github_actions_environment_variable" "test" {
  for_each = local.environment_variables_test

  repository    = var.GitHubRepo
  environment   = github_repository_environment.env["test"].environment
  variable_name = each.key
  value         = each.value
}

resource "github_actions_environment_variable" "prod" {
  for_each = local.environment_variables_prod

  repository    = var.GitHubRepo
  environment   = github_repository_environment.env["prod"].environment
  variable_name = each.key
  value         = each.value
}