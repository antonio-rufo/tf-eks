###############################################################################
# Variables - S3 Buckets
###############################################################################
variable "region" {
  description = "Default Region"
  default     = "ap-southeast-2"
}

variable "tags" {
  description = "Tags to apply to AWS IAM Roles resources"
  type        = map(string)
  default     = {}
}

variable "bucket_name" {
  description = "S3 Bucket name"
}
