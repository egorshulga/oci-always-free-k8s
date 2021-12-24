#!/bin/bash -x

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config-external
sudo chown $(id -u):$(id -g) $HOME/.kube/config-external
sed -i 's/${leader-fqdn}/${leader-public-ip}/' ~/.kube/config-external
