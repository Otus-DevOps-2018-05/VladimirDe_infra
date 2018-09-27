#!/usr/bin/env bash

# Due to bug https://github.com/wata727/tflint/issues/167
# disable module from hashicorp modules registry
for DIR in terraform/{,stage,prod};do
    docker run --rm -v "$(pwd)/terraform":/data -t wata727/tflint ${DIR} --ignore-module=SweetOps/storage-bucket/google
done
