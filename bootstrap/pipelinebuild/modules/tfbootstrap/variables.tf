# Account Settings
variable "Region" {
  description = "AWS deployment region"
  type        = string
}

# Tagging and naming
variable "Prefix" {
  description = "Prefix used to name all resources"
  type        = string
}
variable "EnvCode" {
  description = "Identifier for the environment"
  type        = string
}

# Github Settings
variable "GitHubOrg" {
  description = "GitHub Organization / GitHub username"
  type        = string
}
variable "GitHubRepo" {
  description = "GitHub repository name"
  type        = string
}
variable "GitHubEnv" {
  description = "GitHub Environment for commits"
  type        = string
}