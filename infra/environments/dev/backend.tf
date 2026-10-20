# State is stored in GitLab-managed Terraform state.
# Connection settings are passed through TF_HTTP_* environment variables,
# so no credentials are written to this file. See README.md.
terraform {
  backend "http" {}
}
