#!/bin/bash -x

# k8s requires 2 CPUs. We override this requirement (to better use resources from the Always Free tier).
# We also ignore memory requirement, as for testing we deploy cluster to micro shapes.
sudo kubeadm init \
  --ignore-preflight-errors=NumCPU,Mem \
  --control-plane-endpoint=${leader-fqdn} \
  --pod-network-cidr=10.244.0.0/16 \
  --token=${k8s_discovery_token} \
  ${cluster-dns-name == null ? "\\" : "--apiserver-cert-extra-sans=${cluster-dns-name} \\"}
  --apiserver-cert-extra-sans=${cluster-public-ip}
