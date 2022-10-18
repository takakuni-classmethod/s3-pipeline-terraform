####################################
# S3 Bucket
####################################
resource "aws_s3_bucket" "static_hosting" {
  bucket = "${var.prefix}-static-hosting-pipeline"
  force_destroy = true
}

# サーバーサイド暗号化
resource "aws_s3_bucket_server_side_encryption_configuration" "static_hosting" {
  bucket = aws_s3_bucket.static_hosting.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.static_hosting.id
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# ACL無効化
resource "aws_s3_bucket_ownership_controls" "static_hosting" {
  bucket = aws_s3_bucket.static_hosting.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# バケットポリシー
resource "aws_s3_bucket_policy" "static_hosting" {
  bucket = aws_s3_bucket.static_hosting.id
  policy = data.aws_iam_policy_document.bucket_static_hosting.json
}

data "aws_iam_policy_document" "bucket_static_hosting" {
  version = "2012-10-17"
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static_hosting.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudfront_distribution.static_hosting.arn]
    }
  }
}

# パブリックブロックアクセス
resource "aws_s3_bucket_public_access_block" "static_hosting" {
  bucket                  = aws_s3_bucket.static_hosting.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [
    aws_s3_bucket_policy.static_hosting,
    aws_s3_bucket_ownership_controls.static_hosting
  ]
}

####################################
# S3 Bucket (Artifact)
####################################
resource "aws_s3_bucket" "static_hosting_artifact" {
  bucket = "${var.prefix}-static-hosting-pipeline-artifact"
  force_destroy = true
}

# サーバーサイド暗号化
resource "aws_s3_bucket_server_side_encryption_configuration" "static_hosting_artifact" {
  bucket = aws_s3_bucket.static_hosting_artifact.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.static_hosting_artifact.id
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# ACL無効化
resource "aws_s3_bucket_ownership_controls" "static_hosting_artifact" {
  bucket = aws_s3_bucket.static_hosting_artifact.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# パブリックブロックアクセス
resource "aws_s3_bucket_public_access_block" "static_hosting_artifact" {
  bucket                  = aws_s3_bucket.static_hosting_artifact.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [
    aws_s3_bucket_ownership_controls.static_hosting_artifact
  ]
}