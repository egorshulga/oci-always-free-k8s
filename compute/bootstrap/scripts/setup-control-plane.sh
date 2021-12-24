#!/bin/bash -x

# k8s requires 2 CPUs. We override this requirement (to better use resources from the Always Free tier).
# We also ignore memory requirement, as for testing we deploy cluster to micro shapes.
sudo kubeadm init \
  --ignore-preflight-errors=NumCPU,Mem \
  --control-plane-endpoint=${leader-fqdn} \
  --pod-network-cidr=10.244.0.0/16 \
  --token=${token} \
  --apiserver-cert-extra-sans=${leader-public-ip}
