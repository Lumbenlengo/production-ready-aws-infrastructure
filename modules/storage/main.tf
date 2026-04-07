# modules/storage/main.tf

# ── S3 Artifacts Bucket ───────────────────────────────────────────────

resource "aws_s3_bucket" "artifacts" {
  bucket        = "${var.project_name}-artifacts-${var.environment}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-artifacts"
  }
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    id     = "expire-old-artifacts"
    status = "Enabled"

    filter {
      prefix = ""  # ← Adicionar isto (ou filter vazio para todos)
    }

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# ── DynamoDB Metrics Table ────────────────────────────────────────────

resource "aws_dynamodb_table" "metrics" {
  name         = "${var.project_name}-metrics-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "MetricId"
  range_key    = "Timestamp"

  attribute {
    name = "MetricId"
    type = "S"
  }

  attribute {
    name = "Timestamp"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-metrics"
  }
}
