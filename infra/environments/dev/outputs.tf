output "server_public_ip" {
  description = "Public IP of the control-plane node."
  value       = module.cluster.server_public_ip
}

output "ssh_command" {
  description = "Command to SSH into the control-plane node."
  value       = module.cluster.ssh_command
}

output "tunnel_command" {
  description = "Opens an SSH tunnel so kubectl can reach the API at https://127.0.0.1:16443."
  value       = module.cluster.tunnel_command
}
