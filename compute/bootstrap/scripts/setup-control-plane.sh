#!/bin/bash -x

# k8s requires 2 CPUs. We override this requirement (to better use resources from the Always Free tier).
# We also ignore memory requirement, as for testing we deploy cluster to micro shapes.
sudo kubeadm init \
  --ignore-preflight-errors=NumCPU,Mem \
  --control-plane-endpoint=${leader-fqdn} \
  --pod-network-cidr=10.244.0.0/16 \
  --token=${token}

USER=ubuntu

# Prepare kube config
mkdir -p /home/$USER/.kube
sudo cp /etc/kubernetes/admin.conf /home/$USER/.kube/config
sudo chown $(id -u):$(id -g) /home/$USER/.kube/config

# Setup cluster network - Calico
# kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Setup cluster network - Flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
