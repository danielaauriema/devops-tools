#!/bin/bash
ANSIBLE_PATH="$(dirname $(realpath ${BASH_SOURCE[0]}))"
INVENTORY_PATH=${1:-$ANSIBLE_PATH/inventory}
if [ -n "$2" ]; then
    ARGS=()
    ARGS+=("--tags")
    ARGS+=("$2")
fi
ansible-playbook $ANSIBLE_PATH/devops-tools.yml -i "$INVENTORY_PATH" ${ARGS[@]}
