#!/usr/bin/env bash

for TEMPLATE in packer/*.json;do
    docker run -i  -t --volume $(pwd):/data --workdir /data packer-ansible validate -var-file=packer/variables.json.example ${TEMPLATE}
done
