locals {
  tags = merge(var.tags, {
    Cluster   = var.cluster_name
    ManagedBy = "terraform"
  })

  argocd_manifest = templatefile("${path.module}/templates/argocd.yaml.tftpl", {
    argocd_chart_version      = var.argocd_chart_version
    argocd_apps_chart_version = var.argocd_apps_chart_version
    gitops_repo_url           = var.gitops_repo_url
    gitops_revision           = var.gitops_revision
    gitops_path               = var.gitops_path
  })
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "random_password" "k3s_token" {
  length  = 32
  special = false
}

resource "aws_key_pair" "this" {
  key_name   = "${var.cluster_name}-key"
  public_key = var.ssh_public_key
  tags       = local.tags
}

resource "aws_security_group" "this" {
  name        = "${var.cluster_name}-sg"
  description = "Security group for the ${var.cluster_name} k3s cluster"

  # Key-only SSH. The Kubernetes API (6443) is deliberately not exposed;
  # kubectl reaches it through an SSH tunnel (see scripts/kubeconfig-dev.sh).
  ingress {
    description = "SSH (key-only)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
  }

  ingress {
    description = "All traffic between cluster nodes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  dynamic "ingress" {
    for_each = var.public_ports
    content {
      description = "Public port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${var.cluster_name}-sg" })
}

resource "aws_instance" "server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.this.key_name
  vpc_security_group_ids = [aws_security_group.this.id]

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  # user_data only runs on first boot, so any change to it must recreate the instance.
  user_data_replace_on_change = true

  user_data = templatefile("${path.module}/templates/server-init.sh.tftpl", {
    k3s_version     = var.k3s_version
    k3s_token       = random_password.k3s_token.result
    install_argocd  = var.install_argocd
    argocd_manifest = local.argocd_manifest
  })

  tags = merge(local.tags, { Name = "${var.cluster_name}-server", Role = "server" })
}

resource "aws_instance" "agent" {
  count = var.node_count - 1

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.this.key_name
  vpc_security_group_ids = [aws_security_group.this.id]

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail
    curl -sfL https://get.k3s.io | \
      INSTALL_K3S_VERSION="${var.k3s_version}" \
      K3S_TOKEN="${random_password.k3s_token.result}" \
      K3S_URL="https://${aws_instance.server.private_ip}:6443" \
      sh -
  EOF

  tags = merge(local.tags, { Name = "${var.cluster_name}-agent-${count.index + 1}", Role = "agent" })
}
