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

output "kubeconfig_command" {
  description = "Command that downloads a kubeconfig pointing at the cluster's public IP."
  value       = "ssh ubuntu@${aws_instance.server.public_ip} cat /etc/rancher/k3s/k3s.yaml | sed 's/127.0.0.1/${aws_instance.server.public_ip}/' > kubeconfig-${var.cluster_name}.yaml"
}
