### This module sets up AWS resources for Terraform bootstrapping across multiple accounts

# Create Amazon S3 buckets for Terraform state file
resource "aws_s3_bucket" "tfstate" {
  bucket_prefix = format("%s%s%s%s", var.Prefix, "sss", var.EnvCode, "tfstate")
  force_destroy = true

  tags = {
    Name      = format("%s%s%s%s", var.Prefix, "sss", var.EnvCode, "tfstate"),
    rtype     = "storage"
    codeblock = "infrastructure"
  }
}

# IAM Policy to enforce TLS 1.2 on Amazon S3 buckets
data "aws_iam_policy_document" "S3tfstateTLS" {
  statement {
    sid    = "Allow HTTPS only"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3*"
    ]
    resources = [
      "${aws_s3_bucket.tfstate.arn}",
      "${aws_s3_bucket.tfstate.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }
  statement {
    sid    = "Allow TLS 1.2 and above"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3*"
    ]
    resources = [
      "${aws_s3_bucket.tfstate.arn}",
      "${aws_s3_bucket.tfstate.arn}/*"
    ]
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values = [
        "1.2"
      ]
    }
  }
}

# Apply policy to enforce TLS 1.2 on Amazon S3 buckets
resource "aws_s3_bucket_policy" "tfstate" {
  bucket   = aws_s3_bucket.tfstate.id
  policy   = data.aws_iam_policy_document.S3tfstateTLS.json
}

# Enable Amazon S3 Bucket versioning
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket   = aws_s3_bucket.tfstate.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Block Amazon S3 Bucket public access
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create Amazon DynamoDB tables for Terraform state locking
resource "aws_dynamodb_table" "tfstate" {
  name           = format("%s%s%s%s", var.Prefix, "ddb", var.EnvCode, "tfstate")
  hash_key       = "LockID"
  # Billing Mode depends on usage patterns. Change as appropriate
  # read_capacity  = 20
  # write_capacity = 20
  billing_mode   = "PAY_PER_REQUEST"
 
  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
   enabled = true
  }

  server_side_encryption {
    enabled = true
  }
}

# GitHub OIDC Configuration 
# https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services

# Fetch latest TLS cert from GitHub to authenticate requests
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

# IAM policy to allow assume role
data "aws_iam_policy_document" "ghaassumerole" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["${aws_iam_openid_connect_provider.github_actions.arn}"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.GitHubOrg}/${var.GitHubRepo}:environment:${var.GitHubEnv}"]
    }
  }
}

# IAM policy allowing Github to create and manage AWS resources
data "aws_iam_policy_document" "TerraformState" {
  # Terraform state Amazon S3 access
  statement {
    actions   = [
      "s3:List*",
      "s3:Get*",
      "s3:Put*",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion"
    ]
    resources = [
      "${aws_s3_bucket.tfstate.arn}",
      "${aws_s3_bucket.tfstate.arn}/*"
      ]
  }
  # Terraform state Amazon DynamoDB access
  statement {
    actions   = [
      "dynamodb:BatchGetItem",
      "dynamodb:Query",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:Describe*",
      "dynamodb:Get*",
      "dynamodb:List*"
    ]
    resources = [
      "${aws_dynamodb_table.tfstate.arn}"
      ]
  }
}

# Create OIDC Provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

# Define IAM Role configured for assuming the role with web identity, tailored for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name               = format("%s%s%s%s", var.Prefix, "iar", var.EnvCode, "gha")
  assume_role_policy = data.aws_iam_policy_document.ghaassumerole.json

    inline_policy {
    name   = format("%s%s%s%s", var.Prefix, "iap", var.EnvCode, "TerraformState")
    policy = data.aws_iam_policy_document.TerraformState.json
  }
    inline_policy {
    name   = format("%s%s%s%s", var.Prefix, "iap", var.EnvCode, "SampleApp")
    policy = data.aws_iam_policy_document.SampleApp.json
  }

  tags = {
    Name  = format("%s%s%s%s", var.Prefix, "iar", var.EnvCode, "gha")
    rtype = "security"
  }
}

# Outputs used to create GitHub resources
output "gha_iam_role" {
  value = aws_iam_role.github_actions.arn
}
output "tfstate_bucket_name" {
  value = aws_s3_bucket.tfstate.bucket
}
output "tfstate_dynamodb_table_name" {
  value = aws_dynamodb_table.tfstate.name
}