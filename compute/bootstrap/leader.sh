#!/bin/bash

sudo apt-get update
sudo apt-get upgrade --yes

echo 'This instance was provisioned by Terraform.' >> /etc/motd
