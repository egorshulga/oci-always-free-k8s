#!/bin/bash -x

# Setup cluster network - Calico
# kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Setup cluster network - Flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
