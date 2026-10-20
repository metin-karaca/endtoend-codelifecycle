output "server_public_ip" {
  description = "Public IP of the control-plane node."
  value       = module.cluster.server_public_ip
}

output "ssh_command" {
  description = "Command to SSH into the control-plane node."
  value       = module.cluster.ssh_command
}

output "kubeconfig_command" {
  description = "Command that downloads a kubeconfig for this cluster."
  value       = module.cluster.kubeconfig_command
}
