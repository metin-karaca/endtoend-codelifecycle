variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "EC2 instance type for the cluster nodes."
  type        = string
  default     = "t3.medium"
}

variable "ssh_public_key" {
  description = "SSH public key content (the line from ~/.ssh/id_ed25519.pub)."
  type        = string
}
