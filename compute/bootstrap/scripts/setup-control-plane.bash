#!/bin/bash

# k8s requires 2 CPUs. We override this requirement (to better use resources from the Always Free tier).
sudo kubeadm init --ignore-preflight-errors=NumCPU --control-plane-endpoint=${leader-domain-name}
