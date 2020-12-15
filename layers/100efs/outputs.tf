###############################################################################
# EFS SG Output
###############################################################################
output "efs_sg_id" {
  description = "The ID of the security group."
  value       = aws_security_group.efs_sg.id
}

output "efs_sg_name" {
  description = "The Name of the security group."
  value       = aws_security_group.efs_sg.name
}

output "efs_id" {
  description = "The ID that identifies the file system."
  value       = aws_efs_file_system.eks_efs.id
}

output "efs_mount_taget_id_1" {
  description = "The ID of the mount target."
  value       = aws_efs_mount_target.eks_efs_mount_point_1.id
}

output "efs_mount_taget_id_2" {
  description = "The ID of the mount target."
  value       = aws_efs_mount_target.eks_efs_mount_point_2.id
}

output "efs_mount_taget_id_3" {
  description = "The ID of the mount target."
  value       = aws_efs_mount_target.eks_efs_mount_point_3.id
}
