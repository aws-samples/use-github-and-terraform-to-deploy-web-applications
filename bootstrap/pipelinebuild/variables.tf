# Regions
variable "Region" {
  description = "AWS deployment region"
  type        = string
}

# Tagging and naming
variable "Prefix" {
  description = "Prefix used to name all resources"
  type        = string
}

# Assumed Role ARNs
variable "dev_role_arn" {
  description = "Dev environment deployment role created in bootstrap/accountsetup"
  type        = string
}
variable "test_role_arn" {
  description = "Test environment deployment role created in bootstrap/accountsetup"
  type        = string
}
variable "prod_role_arn" {
  description = "Prod environment deployment role created in bootstrap/accountsetup"
  type        = string
}

# GitHub Settings
variable "GitHubOrg" {
  description = "GitHub Organization / GitHub username"
  type        = string
}
variable "GitHubRepo" {
  description = "GitHub repository name"
  type        = string
}
variable "InfraCostAPIKey" {
  description = "InfraCost API key follow instructions here: https://github.com/infracost/actions?tab=readme-ov-file#quick-start"
  type        = string
}