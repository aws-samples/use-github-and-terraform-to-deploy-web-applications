### Create Amazon ECS Cluster

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "mswebappkms" {
  statement {
    # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-overview.html
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = [
      "kms*"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    # https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html
    sid    = "Allow Cloudwatch access to KMS Key"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.${var.Region}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = [
      "*"
    ]
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values = [
        "arn:aws:logs:${var.Region}:${data.aws_caller_identity.current.account_id}:*"
      ]
    }
  }
}

# Create KMS key for solution
resource "aws_kms_key" "mswebapp" {
  description             = "KMS key to secure various aspects of an example Microsoft .NET web application"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.mswebappkms.json

  tags = {
    Name         = format("%s%s%s%s", var.Prefix, "kms", var.EnvCode, "mswebapp")
    resourcetype = "security"
    codeblock    = "ecscluster"
  }
}

# Create KMS Alias. Only used in this context to provide a friendly display name
resource "aws_kms_alias" "mswebapp" {
  name          = "alias/mswebapp"
  target_key_id = aws_kms_key.mswebapp.key_id
}

# Create CloudWatch log group for ECS logs 
resource "aws_cloudwatch_log_group" "ecscluster" {
  name              = format("%s%s%s%s", var.Prefix, "cwl", var.EnvCode, "ecscluster")
  retention_in_days = 90
  kms_key_id        = aws_kms_key.mswebapp.arn

  tags = {
    Name         = format("%s%s%s%s", var.Prefix, "cwl", var.EnvCode, "ecscluster")
    resourcetype = "monitor"
    codeblock    = "ecscluster"
  }
}

# Create CloudWatch log group for Application logs
resource "aws_cloudwatch_log_group" "mswebapp" {
  name              = format("%s%s%s%s", var.Prefix, "cwl", var.EnvCode, "mswebapp")
  retention_in_days = 30
  kms_key_id        = aws_kms_key.mswebapp.arn

  tags = {
    Name         = format("%s%s%s%s", var.Prefix, "cwl", var.EnvCode, "mswebapp")
    resourcetype = "monitor"
    codeblock    = "ecscluster"
  }
}

# Create Amazon ECR repository to store Docker image
resource "aws_ecr_repository" "mswebapp" {
  name                 = var.ECRRepo
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.mswebapp.arn
  }

  tags = {
    Name         = format("%s%s%s%s", var.Prefix, "ecs", var.EnvCode, "mswebapp")
    resourcetype = "compute"
    codeblock    = "ecscluster"
  }
}

# Create ECR lifecycle policy to delete untagged images after 1 day
resource "aws_ecr_lifecycle_policy" "mswebapp" {
  repository = aws_ecr_repository.mswebapp.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Delete untagged images after one day",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}

# Create Amazon ECS cluster 
resource "aws_ecs_cluster" "mswebapp" {
  name = format("%s%s%s%s", var.Prefix, "ecs", var.EnvCode, "mswebapp")

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.mswebapp.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecscluster.name
      }
    }
  }

  tags = {
    Name         = format("%s%s%s%s", var.Prefix, "ecs", var.EnvCode, "mswebapp")
    resourcetype = "storage"
    codeblock    = "ecscluster"
  }
}

# Establish IAM Role with permissions for Amazon ECS to access Amazon ECR for image pulling and CloudWatch for logging
resource "aws_iam_role" "ecstaskexec" {
  name = format("%s%s%s%s", var.Prefix, "iar", var.EnvCode, "ecstaskexec")
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name  = format("%s%s%s%s", var.Region, "iar", var.EnvCode, "ecstaskexec")
    rtype = "security"
  }
}

resource "aws_iam_role_policy" "ecstaskexec" {
  name = format("%s%s%s%s", var.Region, "irp", var.EnvCode, "ecstaskexec")
  role = aws_iam_role.ecstaskexec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # https://docs.aws.amazon.com/AmazonECR/latest/userguide/security_iam_id-based-policy-examples.html
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Effect   = "Allow"
        Resource = ["*"]
      },
      {
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Effect   = "Allow"
        Resource = ["${aws_ecr_repository.mswebapp.arn}"]
      },
      {
        # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/instance_IAM_role.html#cwl_iam_policy
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = ["arn:aws:logs:*:*:*"]
      }
    ]
  })
}