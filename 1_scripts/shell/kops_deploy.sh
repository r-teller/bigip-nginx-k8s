
#!/bin/bash,
## Install required applications,
sudo apt-get update,
sudo apt-get install jq -y,
sudo apt-get install awscli -y,

### Install kops,
curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | jq -r .tag_name )/kops-linux-amd64,

### Install kubectl,
curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl,

### Move kubectl and kops binary,
chmod +x ./kubectl ./kops,
sudo mv ./kubectl ./kops /usr/local/bin/,

### Start configuration based on environment,
{ Fn::Sub: [ export KOPS_NAME=${StackName}.k8s.local, { StackName: {Ref : AWS::StackName }} ]},
echo export KOPS_NAME=$KOPS_NAME >> /etc/profile.d/88-all-profiles.sh,
{ Fn::Sub: [ export KOPS_STATE_STORE=s3://${BucketName}, { BucketName: {Ref: S3BucketKOPS} }]},
echo export KOPS_STATE_STORE=$KOPS_STATE_STORE >> /etc/profile.d/88-all-profiles.sh,
{ Fn::Sub: [ export KOPS_VPC_ID=${vpcID}, { vpcID: {Ref: VPC} }]},
{ Fn::Sub: [ export KOPS_SUBNET_ID=${SubnetID}, { SubnetID: {Ref: PrivateSubnet01AzA} }]},
{ Fn::Sub: [ export KOPS_AVAIL_ZONES=${AZ}, { AZ: {Fn::GetAtt : [ PrivateSubnet01AzA , AvailabilityZone ]} }]},
{ Fn::Sub: [ export KOPS_SECURITY_GROUP=${SG}, {SG: {Ref : SecurityGroupPrivate} }]},

### Deploy k8s cluster with kops
sudo -u ubuntu kops create cluster \
    --state=${KOPS_STATE_STORE} \
    --cloud=aws \
    --vpc=${KOPS_VPC_ID} \
    --master-zones=${KOPS_AVAIL_ZONES} \
    --master-security-groups=${KOPS_SECURITY_GROUP} \
    --zones=${KOPS_AVAIL_ZONES} \
    --subnets=${KOPS_SUBNET_ID} \
    --utility-subnets=${KOPS_SUBNET_ID} \
    --node-count=1 \
    --topology=private \
    --api-loadbalancer-type=internal \
    --networking=kopeio-vxlan \
    --node-size=t3.medium \
    --node-security-groups=${KOPS_SECURITY_GROUP} \
    --master-size=t3.medium \
    --ssh-public-key=/home/ubuntu/.ssh/authorized_keys \
    --name=${KOPS_NAME} --yes
