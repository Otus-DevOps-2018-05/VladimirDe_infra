#!/usr/bin/env bash

for TEMPLATE in packer/*.json;do
    docker_packer packer/variables.json.example "${TEMPLATE}"
done
