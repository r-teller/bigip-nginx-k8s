# Useful Links
Deploying K8s in AWS with KOPS
* https://github.com/kubernetes/kops/blob/master/docs/aws.md

K8s cheat sheet
* https://kubernetes.io/docs/reference/kubectl/cheatsheet/

NGINX Ingress Controller: Install steps
* https://github.com/nginxinc/kubernetes-ingress/blob/master/docs/installation.md

NGINX Ingress Controller: Complete Example
* https://github.com/nginxinc/kubernetes-ingress/tree/master/examples/complete-example

F5 BIG-IP Controller: Kubernetes
* https://clouddocs.f5.com/containers/v2/kubernetes/kctlr-app-install.html

F5 Application Services 3
* https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/


# Overview
This demo was put in place to simplify the process of deploying F5 BIG-IP & NGINX-Ingress Controller running inside of Kubernetes.

When the CFT is deployed it will create everything needed to complete the demo in AWS.
- AWS Deployment Artifacts
    - VPC with CIDR set to 10.10.0.0/16
    - Public_Subnet_A (10.10.1.0/24)
        - This subnet is used for Mgmt interfaces of devices deployed in the VPC
    - Public_Subnet_B (10.10.2.0/24)
        - This subnet is used to expose resources in the Private subnet to the internet
    - Private_Subnet_A (10.10.3.0/24)
        - This subnet is used to prevent resources from being directly exposed to the internet
    - Internet_Gateway - provides internet connectivity for resources in Public_Subnet_A/B
    - NAT_Gateway - provides internet connectivity for resources in Private_Subnet_A
    - Elastic_IPs - are created for the following resources
        - BIG-IP Mgmt interface
        - BIG-IP VirtualServer Deployment Example A
        - BIG-IP VirtualServer Deployment Example B
        - Jump_Host
        - NAT Gateway

![alt text](/2_images/Env_VPC.png)

## Notes -
### Scaling KOPS worker nodes from 1 to 2
```bash
    kops get ig nodes -o json | jq '.spec.minSize=1|.spec.maxSize=1' | kops replace -f /dev/stdin
    kops update cluster --yes
```
### Disabling Web Session Consistent IP
```bash
    tmsh modify sys httpd auth-pam-validate-ip off
    tmsh modify auth password-policy policy-enforcement disabled
```

### Query AWS to find an AMI in all regions
```bash
    ## Create a list of all Ubuntu AMI per region

    productCode=`curl http://169.254.169.254/latest/meta-data/product-codes`  
    aws ec2 describe-images --filters "Name=product-code,Values=rsd47wz2xdfqgesz2soj5xum" "Name=description,Values=F5 BIGIP-14.1.0.3-0.0.6 PAYG-Best 200Mbps*"

    ami-056ee704806822732

    aws ec2 describe-images  --filters \
        "Name=name,Values=*BIGIP*14.1.0.3-0.0.6*PAYG*Best*200M*" \
         --query 'Images[*].{Name:Name,ID:ImageId,Owner:OwnerId,CreationDate:CreationDate,Code:ProductCodes.ProductCodeId}' --output text
    amiMAP='{}'
    for region in `aws ec2 describe-regions --output text --query 'Regions[*].{ID:RegionName}'`
    do
        amiID=`aws ec2 describe-images  --filters \
            "Name=product-code,Values=rsd47wz2xdfqgesz2soj5xum" \
            "Name=description,Values=F5 BIGIP-14.1.0.3-0.0.6 PAYG-Best 200Mbps*" \
            "Name=owner-id,Values=679593333241" \
            --region ${region} --query 'Images[*].{ID:ImageId}' --output text`

         amiMAP=`echo $amiMAP | jq --arg region "$region" --arg amiID "$amiID" '.[$region]={"AMI": $amiID}'`
    done

    amiMAP='{}'
    for region in `aws ec2 describe-regions --output text --query 'Regions[*].{ID:RegionName}'`
    do
        amiID=`aws ec2 describe-images  --filters \
            "Name=name,Values=amzn2-ami-hvm-2.0.20190618-x86_64-gp2" \
            "Name=owner-id,Values=137112412989" \
            --region ${region} --query 'Images[*].{ID:ImageId}' --output text`

        echo "${region} <> ${amiID}"
         amiMAP=`echo $amiMAP | jq --arg region "$region" --arg amiID "$amiID" '.[$region]={"AMI": $amiID}'`
    done

    for region in `aws ec2 describe-regions --output text --query 'Regions[*].{ID:RegionName}'`
    do
        amiID=`aws ec2 describe-images  --filters \
            "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-20190212.1" \
            "Name=owner-id,Values=099720109477" \
            --region ${region} --query 'Images[*].{ID:ImageId}' --output text`

         amiMAP=`echo $amiMAP | jq --arg region "$region" --arg amiID "$amiID" '.[$region]={"AMI": $amiID}'`
    done
    echo $amiMAP
```

## nginx Deployment & Service
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: coffee-v1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: coffee-v1
  template:
    metadata:
      labels:
        app: coffee-v1
    spec:
      containers:
      - name: coffee-v1
        image: nginxdemos/hello:plain-text
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: coffee-v1-svc
spec:
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    name: http
  selector:
    app: coffee-v1
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: coffee-v2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: coffee-v2
  template:
    metadata:
      labels:
        app: coffee-v2
    spec:
      containers:
      - name: coffee-v2
        image: nginxdemos/hello:plain-text
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: coffee-v2-svc
spec:
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    name: http
  selector:
    app: coffee-v2
```

## nginx-ingress VirtualServer

```yaml
apiVersion: k8s.nginx.org/v1alpha1
kind: VirtualServer
metadata:
  name: cafe
spec:
  host: recruiting.acmefinancial.net
  upstreams:
  - name: recruiting-v1
    service: recruiting-v1-svc
    port: 80
  - name: recruiting-v2
    service: recruiting-v2-svc
    port: 80
  routes:
  - path: /
    splits:
    - weight: 100
      upstream: recruiting-v1
    - weight: 0
      upstream: recruiting-v2
```
