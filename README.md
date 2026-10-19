# End-to-End Code Lifecycle

A production-grade platform that takes code from commit to production: GitLab CI,
GitOps with ArgoCD, and Kubernetes manifests built on a Kustomize base/overlays architecture.

## Project Management

All work is tracked in GitLab issues and grouped into milestones.
Labels, milestones and the issue board are created with `scripts/seed_gitlab.py`.

### Labels

| Label | Scope |
|---|---|
| `infra` | Terraform, clusters, bootstrap |
| `app` | Sample microservices and their manifests |
| `ci` | GitLab CI/CD pipelines and components |
| `gitops` | ArgoCD, environments and promotion |
| `security` | Supply-chain security, policies, scanning |
| `monitoring` | Metrics, dashboards, SLOs and alerting |
| `docs` | Documentation, diagrams, ADRs and demo |
| `setup` | Project and tooling setup |

### Milestones

| Milestone | Goal |
|---|---|
| M0 · Project Setup | Repository structure, conventions, self-hosted runner |
| M1 · Infrastructure | Local clusters, Terraform state, ArgoCD bootstrap |
| M2 · Application | Go microservices and Kustomize base/overlays |
| M3 · CI | Reusable CI/CD components and the main pipeline |
| M4 · GitOps | Environments, image updates, promotion |
| M5 · Security | Image signing, admission policies, SBOMs |
| M6 · Observability | Monitoring, SLO alerts, failure scenario |
| M7 · Documentation & Demo | Architecture, ADRs, docs site, demo video |

### Issue Board

`Open` → `To Do` → `In Progress` → `Review` → `Closed`

## Workflow

`main` is protected: direct pushes are disabled and every change is merged through a merge request.

1. Create a branch from the issue, named `<issue-number>-<short-description>`
   (e.g. `4-terraform-k3d-cluster-module`).
2. Commit using [Conventional Commits](https://www.conventionalcommits.org/)
   and reference the issue (`Refs #4`).
3. Open a merge request with `Closes #4` in the description.
4. Merge after the pipeline passes; the issue closes automatically.