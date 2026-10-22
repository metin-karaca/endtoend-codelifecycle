# dev environment

Single-node k3s cluster on AWS, built from `infra/modules/cluster`.
Terraform state is stored in GitLab (Operate → Terraform states → `dev`).

## Through CI (default)

| Event | What happens |
|---|---|
| Merge request touching `infra/` | `validate` |
| Push to `main` touching `infra/` | `validate` → `plan` → `apply` (cluster is created/updated) |
| Build → Pipelines → **Run pipeline** on `main` | Same as above, without needing a change |
| **destroy** job (▶ button) or Operate → Environments → `dev` → **Stop** | `terraform destroy` |

Required CI/CD variables (Settings → CI/CD → Variables):

| Key | Value | Settings |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | IAM access key | Masked, Protected |
| `AWS_SECRET_ACCESS_KEY` | IAM secret key | Masked and hidden, Protected |
| `TF_VAR_ssh_public_key` | content of `~/.ssh/id_ed25519.pub` | Protected |

## Locally

```bash
cd infra/environments/dev
cp terraform.tfvars.example terraform.tfvars   # fill in ssh_public_key

export GITLAB_TOKEN=<token with api scope>
export TF_HTTP_ADDRESS="https://gitlab.com/api/v4/projects/mtnkrc%2Fendtoend-codelifecycle/terraform/state/dev"
export TF_HTTP_LOCK_ADDRESS="$TF_HTTP_ADDRESS/lock"
export TF_HTTP_UNLOCK_ADDRESS="$TF_HTTP_ADDRESS/lock"
export TF_HTTP_LOCK_METHOD=POST
export TF_HTTP_UNLOCK_METHOD=DELETE
export TF_HTTP_USERNAME=mtnkrc
export TF_HTTP_PASSWORD="$GITLAB_TOKEN"
export TF_HTTP_RETRY_WAIT_MIN=5

terraform init
terraform plan
```

Local runs and CI share the same state, so a cluster created by CI can be inspected
or destroyed from your machine and vice versa.

## Connecting to the cluster

SSH is open to any IP but accepts only your key. The Kubernetes API is not exposed to the
internet; `kubectl` reaches it through an SSH tunnel, so it works from any network.

From the repository root:

```bash
export GITLAB_TOKEN=<token with api scope>
./scripts/kubeconfig-dev.sh            # opens the tunnel and writes ~/.kube/endtoend-dev.yaml
export KUBECONFIG=~/.kube/endtoend-dev.yaml
kubectl get nodes

./scripts/kubeconfig-dev.sh --close    # closes the tunnel
```

## Argo CD

Argo CD is installed at boot by the k3s Helm controller (`infra/modules/cluster/templates/argocd.yaml.tftpl`),
together with a root application that syncs everything under `gitops/` from `main`.
It takes 2–3 minutes after the instance starts.

With the tunnel open and `KUBECONFIG` set:

```bash
kubectl -n argocd get pods
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
kubectl -n argocd port-forward svc/argocd-server 8080:80
```

Open http://localhost:8080 and log in as `admin` with the password above.

The cluster is billed per hour; destroy it when you are done.
