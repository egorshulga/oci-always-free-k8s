#!/bin/bash -x

mkdir -p .kube

kubeadm token generate > .kube/join-token

# k8s requires 2 CPUs. We override this requirement (to better use resources from the Always Free tier).
# We also ignore memory requirement, as for testing we deploy cluster to micro shapes.
sudo kubeadm init \
  --ignore-preflight-errors=NumCPU,Mem \
  --control-plane-endpoint=${leader-fqdn} \
  --pod-network-cidr=10.244.0.0/16 \
  --node-name=${node-name} \
  --token=$(< .kube/join-token) \
  ${cluster-dns-name == null ? "" : "--apiserver-cert-extra-sans=${cluster-dns-name}"} \
  --apiserver-cert-extra-sans=${cluster-public-ip}

openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \
  openssl rsa -pubin -outform der 2>/dev/null | \
  openssl dgst -sha256 -hex | \
  sed 's/^.* //' \
  > .kube/join-hash
