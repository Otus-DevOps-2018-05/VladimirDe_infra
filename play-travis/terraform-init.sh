#!/usr/bin/env bash

for DIR in terraform/{,stage,prod};do
    cp ${DIR}/terraform.tfvars{.example,}
    echo "Copy ${DIR}/terraform.tfvars.example to ${DIR}/terraform.tfvars"
    echo "Initialize terraform in the ${DIR}"
    docker_terraform "${DIR}" init -backend=false
done
