#!/bin/bash -x

# k8s requires 2 CPUs. We override this requirement (to better use resources from the Always Free tier).
# We also ignore memory requirement, as for testing we deploy cluster to micro shapes.
sudo kubeadm join \
  --ignore-preflight-errors NumCPU,Mem \
  --token=${token} \
  --discovery-token-unsafe-skip-ca-verification # Currently we don't pass control plane's CA public key.
