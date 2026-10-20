variable "cluster_name" {
  description = "Name of the cluster. Used as a prefix for all resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.cluster_name))
    error_message = "cluster_name may contain only lowercase letters, numbers and hyphens."
  }
}

variable "instance_type" {
  description = "EC2 instance type for all nodes."
  type        = string
  default     = "t3.medium"
}

variable "node_count" {
  description = "Total number of nodes, including the control-plane node."
  type        = number
  default     = 2

  validation {
    condition     = var.node_count >= 1
    error_message = "node_count must be at least 1 (the control-plane node)."
  }
}

variable "admin_cidr" {
  description = "CIDR allowed to reach the Kubernetes API and SSH, e.g. your public IP as x.x.x.x/32."
  type        = string

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0))
    error_message = "admin_cidr must be a valid CIDR block, e.g. 203.0.113.10/32."
  }
}

variable "public_ports" {
  description = "TCP ports open to the internet (ingress traffic)."
  type        = list(number)
  default     = [80, 443]
}

variable "ssh_public_key" {
  description = "SSH public key content used to access the nodes."
  type        = string
}

variable "k3s_version" {
  description = "k3s version to install, pinned for reproducible clusters."
  type        = string
  default     = "v1.31.4+k3s1"
}

variable "tags" {
  description = "Extra tags added to all resources."
  type        = map(string)
  default     = {}
}
