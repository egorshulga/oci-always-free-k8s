#!/bin/bash -x

# k8s requires 2 CPUs. We override this requirement (to better use resources from the Always Free tier).
# We also ignore memory requirement, as for testing we deploy cluster to micro shapes.
# Currently we don't pass control plane's CA public key.
sudo kubeadm join \
  --ignore-preflight-errors=NumCPU,Mem \
  --node-name=${node_name} \
  --token=$(< .kube/join-token) \
  --discovery-token-unsafe-skip-ca-verification \
  ${leader_url}:6443
  
kubectl label node ${node_name} node-role.kubernetes.io/worker=worker
