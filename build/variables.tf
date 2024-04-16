# Regions
variable "Region" {
  description = "AWS depoloyment region"
  type        = string
}
variable "AZ01" {
  description = "Availability Zone 1"
  type        = string
}
variable "AZ02" {
  description = "Availability Zone 2"
  type        = string
}

# Tagging and naming
variable "Prefix" {
  description = "Prefix used to name all resources"
  type        = string
}
variable "SolTag" {
  description = "Solution tag value. All resources are created with a 'Solution' tag name and the value you set here"
  type        = string
}
variable "GitHubRepo" {
  description = "GitHub repository name"
  type        = string
}
variable "EnvCode" {
  description = "2 character code used to name all resources e.g. 'pd' for production"
  type        = string
}
variable "EnvTag" {
  description = "Environment tag value. All resources are created with an 'Environment' tag name and the value you set here"
  type        = string
}

# Networking
variable "VPCCIDR" {
  description = "VPC CIDR range"
  type        = string
}
variable "PublicIP" {
  description = "Limits mswebapp access to a specified public IP address"
  type        = string
}

# Web App Build
variable "ECRRepo" {
  description = "Name of Amazon ECR repository"
  type        = string
}
variable "ImageTag" {
  description = "Amazon ECR Microsoft sample application Image Tag"
  type        = string
}