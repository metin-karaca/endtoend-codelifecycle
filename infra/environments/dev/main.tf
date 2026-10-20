provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "endtoend-codelifecycle"
      Environment = "dev"
    }
  }
}

module "cluster" {
  source = "../../modules/cluster"

  cluster_name   = "endtoend-dev"
  instance_type  = var.instance_type
  node_count     = 1
  admin_cidr     = var.admin_cidr
  ssh_public_key = var.ssh_public_key
}
