#!/bin/bash
cd /devops-tools
INVENTORY_PATH=./ansible/inventory
ansible-playbook ./ansible/generate-certs.yml -i $INVENTORY_PATH
ansible-playbook ./ansible/devops-tools.yml -i $INVENTORY_PATH
