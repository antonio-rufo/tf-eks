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

output "efs_mount_taget_id" {
  description = "The ID of the mount target."
  value       = aws_efs_mount_target.eks_efs_mount_point.id
}

# ###############################################################################
# # kubectl config
# ###############################################################################
# output "summary" {
#   value = <<EOF
#
# ## Run to configure Kubectl to connect to your new EKS cluster:
# $ aws eks update-kubeconfig --name ${module.eks.cluster_id}
#
# # deploy EFS storage driver
# kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"
#
# EOF
#
#   description = "Configures kubectl so that you can connect to an Amazon EKS cluster. `terraform output summary` "
# }
