###############################################################################
# State Import Example
# terraform output state_import_example
###############################################################################
output "jenkins_setup" {
  description = "Initial setup for Jenkins."

  value = <<EOF

  ### To get the generated password:

  $ kubectl -n jenkins get pods
  $ kubectl -n jenkins logs <pod-name>

  ### To port forward:

  $ kubectl port-forward -n jenkins <pod-name> 8090:8080

  ### In browser:

  localhost:8090

EOF
}
