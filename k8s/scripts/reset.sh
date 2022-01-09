#!/bin/bash -x

kubectl drain ${hostname} --force --ignore-daemonsets
kubectl delete node ${hostname} --force
sudo kubeadm reset --force

# Recreating network
sudo ip link set cni0 down
sudo ip link set flannel.1 down 
sudo ip link delete cni0
sudo ip link delete flannel.1
sudo systemctl restart containerd
sudo systemctl restart kubelet
