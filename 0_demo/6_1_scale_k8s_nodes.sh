#!/bin/bash

kops get ig nodes -o json | jq '.spec.minSize=3|.spec.maxSize=3' | kops replace -f /dev/stdin
kops update cluster --yes
