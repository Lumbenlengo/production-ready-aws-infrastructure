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
    Name = "${var.project_name}-config-role"
  }
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_s3_bucket" "config" {
  bucket        = "${var.project_name}-config-${var.environment}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-config"
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
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
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

resource "aws_config_delivery_channel" "main" {
  name           = "${var.project_name}-channel-${var.environment}"
  s3_bucket_name = aws_s3_bucket.config.bucket
  depends_on     = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}

# ── Config Rules ──────────────────────────────────────────────────────

resource "aws_config_config_rule" "no_public_ip" {
  name = "${var.project_name}-no-public-ip-${var.environment}"

  source {
    owner             = "AWS"
    source_identifier = "NO_UNRESTRICTED_ROUTE_TO_IGW"
  }

  depends_on = [aws_config_configuration_recorder_status.main]

  tags = {
    Name = "${var.project_name}-no-public-ip"
  }
}

resource "aws_config_config_rule" "restricted_ssh" {
  name = "${var.project_name}-restricted-ssh-${var.environment}"

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  depends_on = [aws_config_configuration_recorder_status.main]

  tags = {
    Name = "${var.project_name}-restricted-ssh"
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
    Name = "${var.project_name}-encrypted-volumes"
  }
}

resource "aws_config_config_rule" "s3_public_read_prohibited" {
  name = "${var.project_name}-s3-public-${var.environment}"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder_status.main]

  tags = {
    Name = "${var.project_name}-s3-public"
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
    Name = "${var.project_name}-backup-role"
  }
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_backup_vault" "main" {
  name          = "${var.project_name}-backup-vault-${var.environment}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-backup-vault"
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
    Name = "${var.project_name}-backup-plan"
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
