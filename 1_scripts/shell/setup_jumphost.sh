#!/bin/bash -xe
### Install kops
curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | jq -r .tag_name )/kops-linux-amd64

### Install kubectl
curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl

### Move kubectl and kops binary
chmod +x ./kubectl ./kops
sudo mv ./kubectl ./kops /usr/local/bin/
