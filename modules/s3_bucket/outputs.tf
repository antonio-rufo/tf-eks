###############################################################################
# S3 Bucket ID
###############################################################################
output "bucket_id" {
  description = "The Id of S3 bucket."
  value       = aws_s3_bucket.s3_bucket.id
}

output "bucket_arn" {
  description = "The Id of S3 bucket."
  value       = aws_s3_bucket.s3_bucket.arn
}
