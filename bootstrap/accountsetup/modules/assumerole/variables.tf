# Account Settings
variable "Region" {
  description = "AWS deployment region"
  type        = string
}
variable "PrimaryAccount" {
  description = "ID of the AWS account where the bootstrap will be executed"
  type        = string
}
variable "TargetAccount" {
  description = "ID of the AWS account where Terraform infrastructure will be deployed"
  type        = string
}

# Tagging and naming
variable "Prefix" {
  description = "Prefix used to name all resources"
  type        = string
}
variable "Environment" {
  description = "Identifier for the environment"
  type        = string
}