#!/bin/bash -x

# To make iptables upgrade/installation silent
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections

sudo apt-get clean
sudo apt-get update --yes
sudo apt-get upgrade --yes
