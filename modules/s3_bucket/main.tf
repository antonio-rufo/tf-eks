###############################################################################
# S3 Buckets
###############################################################################
resource "aws_s3_bucket" "s3_bucket" {
  bucket        = var.bucket_name
  region        = var.region
  acl           = "private"
  force_destroy = true
  tags          = var.tags

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

}
