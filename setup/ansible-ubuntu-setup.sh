#!/bin/sh

# Set up ansible on Ubuntu 12 and >
apt-get update && apt-get install software-properties-common -y
apt-add-repository ppa:ansible/ansible -y
apt-get update && apt-get install ansible -y
apt-get install git -y