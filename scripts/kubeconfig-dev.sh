#!/usr/bin/env bash
# Connect kubectl to the dev cluster created by CI.
#
# The Kubernetes API is not exposed to the internet. This script:
#   1. reads the server IP from the GitLab-managed Terraform state,
#   2. opens an SSH tunnel  localhost:16443 -> server:6443,
#   3. writes a kubeconfig that points at the tunnel.
#
# Usage:
#   export GITLAB_TOKEN=<personal access token with api scope>
#   ./scripts/kubeconfig-dev.sh            # connect
#   ./scripts/kubeconfig-dev.sh --close    # close the tunnel
#   export KUBECONFIG=~/.kube/endtoend-dev.yaml
set -euo pipefail

PROJECT="mtnkrc%2Fendtoend-codelifecycle"
STATE_NAME="dev"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519}"
OUT="${OUT:-$HOME/.kube/endtoend-dev.yaml}"
LOCAL_PORT="${LOCAL_PORT:-16443}"
CONTEXT="endtoend-dev"
TUNNEL_PATTERN="${LOCAL_PORT}:127.0.0.1:6443"

close_tunnel() {
  if pkill -f "$TUNNEL_PATTERN" 2>/dev/null; then
    echo "Tunnel on localhost:$LOCAL_PORT closed."
  fi
}

if [ "${1:-}" = "--close" ]; then
  close_tunnel
  exit 0
fi

: "${GITLAB_TOKEN:?Set GITLAB_TOKEN to a GitLab token with the api scope}"
for bin in curl jq ssh kubectl; do
  command -v "$bin" >/dev/null || { echo "missing dependency: $bin" >&2; exit 1; }
done

echo "Reading server IP from Terraform state '$STATE_NAME'..."
IP=$(curl -fsS -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/$PROJECT/terraform/state/$STATE_NAME" \
  | jq -r '.outputs.server_public_ip.value // empty')

if [ -z "$IP" ]; then
  echo "No server IP in state. Is the cluster deployed? (Operate → Environments → dev)" >&2
  exit 1
fi
echo "Server: $IP"

# Instances are recreated often and IPs get reused, so don't pin host keys for this throwaway cluster.
SSH_OPTS=(-i "$SSH_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
          -o LogLevel=ERROR -o ConnectTimeout=5 -o ServerAliveInterval=30)

echo "Waiting for k3s to finish installing..."
for _ in $(seq 1 60); do
  ssh "${SSH_OPTS[@]}" "ubuntu@$IP" test -f /etc/rancher/k3s/k3s.yaml 2>/dev/null && break
  sleep 5
done

mkdir -p "$(dirname "$OUT")"
ssh "${SSH_OPTS[@]}" "ubuntu@$IP" cat /etc/rancher/k3s/k3s.yaml \
  | sed "s#https://127.0.0.1:6443#https://127.0.0.1:${LOCAL_PORT}#" > "$OUT"
chmod 600 "$OUT"
KUBECONFIG="$OUT" kubectl config rename-context default "$CONTEXT" >/dev/null 2>&1 || true

close_tunnel
ssh "${SSH_OPTS[@]}" -f -N -o ExitOnForwardFailure=yes -L "$TUNNEL_PATTERN" "ubuntu@$IP"
echo "Tunnel open: localhost:$LOCAL_PORT -> $IP:6443"

echo
echo "Run:  export KUBECONFIG=$OUT && kubectl get nodes"
echo "Close the tunnel with: $0 --close"
