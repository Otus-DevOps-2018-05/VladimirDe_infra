#!/usr/bin/env bash

for DIR in terraform/{,stage,prod};do
    cp ${DIR}/terraform.tfvars{.example,}
    echo "Copy ${DIR}/terraform.tfvars.example to ${DIR}/terraform.tfvars"
    echo "Initialize terraform in the ${DIR}"
    docker run -i --mount type=bind,source="$(pwd)"/terraform,target=/terraform \
    --mount type=bind,source="${HOME}"/.ssh,target=/root/.ssh \
     --workdir /"${dir}" \
     -t hashicorp/terraform:light init -backend=false
done
