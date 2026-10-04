#!/bin/bash
set -eo pipefail

JENKINS_HOME="${JENKINS_HOME:-/var/jenkins_home}"

# The kubeconfig bind-mounted from macOS points at 127.0.0.1:26443. Inside this
# container 127.0.0.1 means the container itself, so rewrite the server to the
# host alias. OrbStack's API certificate is not issued for that name, so TLS
# verification is disabled - acceptable locally, never against a real cluster.
HOST_KUBECONFIG=/kubeconfig-host/config
DEST="$JENKINS_HOME/.kube/config"

if [ -f "$HOST_KUBECONFIG" ]; then
  mkdir -p "$JENKINS_HOME/.kube"
  cp "$HOST_KUBECONFIG" "$DEST"
  chmod 600 "$DEST"

  export KUBECONFIG="$DEST"
  CLUSTER="$(kubectl config view --minify -o jsonpath='{.contexts[0].context.cluster}')"

  kubectl config unset "clusters.${CLUSTER}.certificate-authority-data" >/dev/null 2>&1 || true
  kubectl config unset "clusters.${CLUSTER}.certificate-authority" >/dev/null 2>&1 || true
  kubectl config set-cluster "$CLUSTER" \
    --server="https://host.docker.internal:26443" \
    --insecure-skip-tls-verify=true >/dev/null

  echo "[entrypoint] cluster '${CLUSTER}' -> $(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')"
else
  echo "[entrypoint] no host kubeconfig at ${HOST_KUBECONFIG}; skipping rewrite"
fi

exec /usr/bin/tini -- /usr/local/bin/jenkins.sh "$@"
