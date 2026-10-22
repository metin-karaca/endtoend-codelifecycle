output "server_public_ip" {
  description = "Public IP of the control-plane node."
  value       = aws_instance.server.public_ip
}

output "server_private_ip" {
  description = "Private IP of the control-plane node."
  value       = aws_instance.server.private_ip
}

output "agent_private_ips" {
  description = "Private IPs of the agent nodes."
  value       = aws_instance.agent[*].private_ip
}

output "ssh_command" {
  description = "Command to SSH into the control-plane node."
  value       = "ssh ubuntu@${aws_instance.server.public_ip}"
}

output "tunnel_command" {
  description = "Opens an SSH tunnel so kubectl can reach the API at https://127.0.0.1:16443."
  value       = "ssh -f -N -L 16443:127.0.0.1:6443 ubuntu@${aws_instance.server.public_ip}"
}
