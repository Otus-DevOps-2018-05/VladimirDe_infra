#!/usr/bin/env bash

for DIR in terraform/{,stage,prod};do
    docker run -i --mount type=bind,source="$(pwd)"/terraform,target=/terraform \
    --mount type=bind,source="${HOME}"/.ssh,target=/root/.ssh \
     --workdir /"${DIR}" \
     -t hashicorp/terraform:light "validate"
    logger --tag terraform-validate --stderr -p user.info "Run terraform validate in the ${DIR}"
done
