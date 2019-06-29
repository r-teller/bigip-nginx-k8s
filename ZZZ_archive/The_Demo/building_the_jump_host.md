## Instal JQ
```bash
sudo apt-get install jq
```


## Install kubectl
```bash
curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

## Install AWScli
```bash
sudo apt-get install awscli -y
```

### Find AWS Region
```bash
EC2_REGION=`curl -s 169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/.$//'`
```
### Set AWS Region
```bash
 aws configure set region $EC2_REGION
 ```

 ## Install kops

 ```bash
 curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
 chmod +x ./kops
 sudo mv ./kops /usr/local/bin/
 ```


### Configure S3 Bucket
```bash
## Note move to CFT
aws s3api create-bucket \
    --bucket kops-testingv2 \
    --region $EC2_REGION \
    --create-bucket-configuration LocationConstraint=$EC2_REGION
```

### Store S3 Bucket Information as ENV
```bash
export NAME=kops-demo.k8s.local
export KOPS_STATE_STORE=s3://kops-testingv2
```

### Deploy kops
```bash

# Identify if selected region has 3 or more AZ
AVAIL_ZONES=`aws ec2 describe-availability-zones`
INSTANCE_ID=`curl http://169.254.169.254/latest/meta-data/instance-id`
VPC_ID=`aws ec2 describe-instances --instance-ids $INSTANCE_ID | jq -r .[][].Instances[].VpcId`
if (( `echo $AVAIL_ZONES | jq '.AvailabilityZones|length'` >= 3 )); then
    MASTER_ZONES=`echo $AVAIL_ZONES | jq -r '.[]| map(.ZoneName) | join(",")'`
else
    MASTER_ZONES=`echo $AVAIL_ZONES | jq -r '.[][0].ZoneName'`
fi



kops create cluster \
    --cloud aws \
    --vpc ${VPC_ID} \
    --master-zones us-west-1b \
    --zones us-west-1b \
    --subnets subnet-0507641555fbcc808 \
    --utility-subnets subnet-0507641555fbcc808 \
    --node-count=1 \
    --topology private \
    --api-loadbalancer-type internal \
    --networking kopeio-vxlan \
    --node-size=t3.medium \
    --master-size=t3.medium \
    --ssh-public-key ~/.ssh/authorized_keys \
    ${NAME}


```
