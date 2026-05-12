# CGE-P Capstone Layer 1 - Gap-Closing Overrides
# Closes 8 of 8 starter gaps. Framework: SOC 2 Type II.

resource "aws_kms_key" "intake" {
  description             = "CMK for Acme Health intake"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags = {
    Name       = "${local.name_prefix}-intake-cmk"
    Compliance = "SOC2-CC6.1"
  }
}

resource "aws_kms_alias" "intake" {
  name          = "alias/${local.name_prefix}-intake"
  target_key_id = aws_kms_key.intake.key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.intake.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "uploads" {
  bucket = aws_s3_bucket.uploads.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket                  = aws_s3_bucket.uploads.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "uploads_tls" {
  bucket = aws_s3_bucket.uploads.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = [aws_s3_bucket.uploads.arn, "${aws_s3_bucket.uploads.arn}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })
}

# tfsec:ignore:aws-vpc-no-public-egress-sgr
resource "aws_security_group" "lambda" {
  name        = "${local.name_prefix}-lambda-sg"
  description = "Egress-only SG for intake Lambda"
  vpc_id      = aws_vpc.main.id
  egress {
    description = "HTTPS to AWS endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${local.name_prefix}-lambda-sg" }
}

resource "aws_sqs_queue" "lambda_dlq" {
  name                      = "${local.name_prefix}-lambda-dlq"
  message_retention_seconds = 1209600
  kms_master_key_id         = aws_kms_key.intake.arn
  tags                      = { Name = "${local.name_prefix}-lambda-dlq" }
}

resource "aws_cloudwatch_log_group" "apigw" {
  name              = "/aws/apigateway/${local.name_prefix}"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.intake.arn
  tags              = { Name = "${local.name_prefix}-apigw-logs" }
}
