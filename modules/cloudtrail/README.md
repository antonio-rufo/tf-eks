# terraform-aws-cloudtrail

This layer creates the CloudTrail

## Basic Usage

```hcl
module "cloudtrail" {
  source                        = "../../../../../../../../../terraform_modules_shared/security_identity_compliance/cloudtrail/"
  name                          = var.name
  enable_log_file_validation    = var.enable_log_file_validation
  include_global_service_events = var.include_global_service_events
  is_multi_region_trail         = var.is_multi_region_trail
  enable_logging                = var.enable_logging
  s3_bucket_name                = data.terraform_remote_state.cloudtrail_bucket.outputs.cloudtrail_bucket_id
  tags                          = local.tags
  kms_key_arn                   = var.kms_key_arn
  cloud_watch_logs_role_arn     = data.terraform_remote_state.cloudtrail_role.outputs.cloudwatchlogs_role_arn
  cloud_watch_logs_group_arn    = data.terraform_remote_state.cloudtrail_cwl.outputs.cloudwatchlogs_arn
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| name | Name for CloudTrail trail. | string | n/a | yes |
| enable\_logging | Enable logging for the Trail. | bool | true | no |
| s3\_bucket\_name | S3 bucket name for CloudTrail logs. | string | n/a | no |
| enable\_log\_file\_validation | Specifies whether log file integrity validation is enabled. Creates signed digest for validated contents of logs. | bool | true | no |
| is\_multi\_region\_trail | Specifies whether the trail is created in the current region or in all regions. | bool | false | no |
| include\_global\_service\_events | Specifies whether the trail is publishing events from global services such as IAM to the log files. | string | false | no |
| cloud\_watch\_logs\_role\_arn | Specifies the role for the CloudWatch Logs endpoint to assume to write to a user’s log group. | string | n/a | no |
| cloud\_watch\_logs\_group\_arn | Specifies a log group name using an Amazon Resource Name (ARN), that represents the log group to which CloudTrail logs will be delivered. | string | n/a | no |
| tags | Tags for Cloudtrail. | map(string) | n/a | no |
| kms\_key\_arn | Specifies the KMS key ARN to use to encrypt the logs delivered by CloudTrail. | string | n/a | no |
| is_organization_trail  | The trail is an AWS Organizations trail. | bool | false | no |

## Outputs

| Name | Description |
|------|-------------|
| cloudtrail\_id | The name of the trail. |
| cloudtrail\_home\_region | The region in which the trail was created. |
| cloudtrail\_arn | The Amazon Resource Name of the trail. |
