# modules/compliance/main.tf

# ── AWS Config ────────────────────────────────────────────────────────

resource "aws_iam_role" "config" {
  name = "${var.project_name}-config-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
    }]
  })

  tags = {
    Name        = "${var.project_name}-config-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_s3_bucket" "config" {
  bucket        = "${var.project_name}-config-${var.environment}"
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-config"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket                  = aws_s3_bucket.config.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "config" {
  bucket     = aws_s3_bucket.config.id
  depends_on = [aws_s3_bucket_public_access_block.config]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSConfigBucketPermissionsCheck"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.config.arn
      },
      {
        Sid       = "AWSConfigBucketDelivery"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.config.arn}/AWSLogs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project_name}-recorder-${var.environment}"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# This resource actually STARTS the recorder.
# Without it the recorder exists but never records — a silent failure.
resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

resource "aws_config_delivery_channel" "main" {
  name           = "${var.project_name}-channel-${var.environment}"
  s3_bucket_name = aws_s3_bucket.config.bucket

  depends_on = [aws_config_configuration_recorder.main]
}

# Config Rules
resource "aws_config_config_rule" "s3_public" {
  name = "${var.project_name}-s3-public-${var.environment}"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder_status.main]

  tags = {
    Name        = "${var.project_name}-s3-public"
    Environment = var.environment
  }
}

resource "aws_config_config_rule" "vpc_flow_logs" {
  name = "${var.project_name}-vpc-flow-logs-${var.environment}"

  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }

  input_parameters = jsonencode({ trafficType = "ALL" })

  depends_on = [aws_config_configuration_recorder_status.main]

  tags = {
    Name        = "${var.project_name}-vpc-flow-logs"
    Environment = var.environment
  }
}

resource "aws_config_config_rule" "encrypted_volumes" {
  name = "${var.project_name}-encrypted-volumes-${var.environment}"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  depends_on = [aws_config_configuration_recorder_status.main]

  tags = {
    Name        = "${var.project_name}-encrypted-volumes"
    Environment = var.environment
  }
}

# ── AWS Backup ────────────────────────────────────────────────────────

resource "aws_iam_role" "backup" {
  name = "${var.project_name}-backup-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
    }]
  })

  tags = {
    Name        = "${var.project_name}-backup-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_backup_vault" "main" {
  name = "${var.project_name}-backup-vault-${var.environment}"

  tags = {
    Name        = "${var.project_name}-backup-vault"
    Environment = var.environment
  }
}

resource "aws_backup_plan" "main" {
  name = "${var.project_name}-backup-plan-${var.environment}"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 * * ? *)"

    lifecycle {
      delete_after = var.environment == "prod" ? 30 : 14
    }
  }

  tags = {
    Name        = "${var.project_name}-backup-plan"
    Environment = var.environment
  }
}

resource "aws_backup_selection" "main" {
  name         = "${var.project_name}-backup-selection-${var.environment}"
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = aws_iam_role.backup.arn

  resources = [
    var.dynamodb_table_arn,
    "arn:aws:s3:::${var.artifact_bucket_id}"
  ]
}
