# Useful Links
* Deploying K8s in AWS with KOPS
    * https://github.com/kubernetes/kops/blob/master/docs/aws.md
* K8s cheat sheet
    * https://kubernetes.io/docs/reference/kubectl/cheatsheet/
* NGINX Ingress Controller: Install steps
    * https://github.com/nginxinc/kubernetes-ingress/blob/master/docs/installation.md
* NGINX Ingress Controller: Complete Example
    * https://github.com/nginxinc/kubernetes-ingress/tree/master/examples/complete-example
* F5 BIG-IP Controller: Kubernetes
    * https://clouddocs.f5.com/containers/v2/kubernetes/kctlr-app-install.html
* F5 Application Services 3
    * https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/

# Demo Steps
* For demo information see --> [Demo Steps](/0_demo/readme.md)
* CloudFormation Template --> [demo_cft.json](/1_scripts/cft/demo_cft.json)
* Please note that the PAYG license for Big-IP requires acceptance of terms and subscription. https://aws.amazon.com/marketplace/server/procurement?productId=0d09bfd3-90c5-4b9c-98a2-c3860dbfcd9e

# Overview
This demo was put in place to simplify the process of deploying F5 BIG-IP & NGINX-Ingress Controller running inside of Kubernetes and was based on the bridging the divide webinar.

The provided CFT will create all required decencies in AWS and deploy a configured Big-IP and Kubernetes environment. Once the environment is created you will be able to demo the following scenarios
1.	Big-IP acting as the initial point of ingress into a customers environment with a manually configured virtual-server managed by David that is able to dynamically forward traffic to nginx-ingress controller that is owned by Olivia
2.	Big-IP acting as the initial point of ingress into a customers environment with a dynamically configured virtual-server that is able to dynamically forward traffic to nginx-ingress controller, both objects are managed by Olivia
3.	Olivia easily adds OWASP top 10 protection to her application by updating the K8s configuration
4.	Olivia easily adds HTTPS termination to her application by updating the K8s configuration

If you haven’t seen the webinar you can find it at https://gateway.on24.com/wcc/gateway/f5networks/1140560/2020361/bridging-the-divide-our-joint-vision-for-adc-services


## AWS
![Example VPC Architecture](/2_images/Env_VPC.png)

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
    - S3 Bucket - Used to store K8s configurations
    - IAM Role - Provides Read/Write access to EC2, NLB, IAM and S3 resources in AWS
    - EC2 Instances
        - JumpHost - T3.Medium AMI built from AWS AWSLinux2, cloudinit is used to install all software dependencies and deploy K8s
        - Big-IP - T2.Large AMI, cloudinit is used to establish initial configuration
        - DockerHost - T3.Medium AMI built from Ubuntu 18.04, cloudinit is used to setup a docker registry and build nginx-plus-ingress if licensed
    - Elastic_IPs - are allocated for the following resources
        - BIG-IP Mgmt interface
        - BIG-IP VirtualServer Deployment Example A
        - BIG-IP VirtualServer Deployment Example B
        - Jump_Host
        - NAT Gateway
    - Elastic Network Adapters
        - JumpHost Mgmt Interface (Eth0)
            - Primary Address: 10.10.1.10
                - Maps to allocated EIP
            - Security Group:
                - Allow SSH from 0.0.0.0/0
        - Big-IP Mgmt Interface (Eth0)
            - Primary Address: 10.10.1.50
                - Maps to allocated EIP
            - Security Group:
                - Allow SSH from 0.0.0.0/0
                - Allow HTTPS from 0.0.0.0/0
        - Big-IP Public Interface (Eth1)
            - Primary Address: 10.10.2.50
            - Secondary Address: 10.10.2.51
            - Secondary Address: 10.10.2.52
            - Secondary Address: 10.10.2.60
                - Maps to allocated EIP
            - Secondary Address: 10.10.2.70
                - Maps to allocated EIP
            - Security Group:
                - Allow TCP/80,443,8080,8443 from 0.0.0.0/0
        - Big-IP Private Interface (Eth2)
            - Primary Address: 10.10.3.50
            - Secondary Address: 10.10.3.51
            - Secondary Address: 10.10.3.52
            - Security Group:
                - Allow all traffic from 10.10.0.0/16      
        - DockerHost Private Interface (Eth0)
            - Primary Address: 10.10.3.20
                - Security Group:
                    - Allow all traffic from 10.10.0.0/16

## Kubernetes
After the jump host finishes initializing cloudinit provision two additional EC2 instances (T3.Medium) using KOPs. These instances are deployed in the Private_Subnet and use AutoScale groups to manage scale. The K8s configuration is stored in a S3 Bucket.

- Useful KOPs commands
    - kops get cluster --name ${KOPS_NAME} -o yaml
        - output the current configuration of your K8s cluster in YAML
    - kops get ig --name ${KOPS_NAME}
        - returns current autoscale configuration for your K8s cluster
- Useful K8s commands
    - kubectl get nodes
        - returns all nodes for your K8s cluster
    - kubectl get namespace
        - returns all namespaces, you will notice that nginx-ingress and bigip-ingress were already created during platform standup
    - kubectl get pods -n bigip-ingress
        - returns all pods in the bigip-ingress namespace, you should see the k8s-bigip-ctlr already running and connected to your Big-IP
    - kubectl apply -f /var/tmp/bigip-nginx-k8s/0_demo/2_1_deploy_demo-app-v1_Deployment.yaml
        - applies the yaml spec specified in the referenced file, this example would create the pods for demo-app-v1

## Big-IP
When you SSH into a Big-IP your default terminal is TMSH, to exit into bash you will need to type bash

```bash
    Last login: Mon Jul 15 16:06:59 2019 from 50.204.110.20
    admin@(ip-10-10-1-50)(cfg-sync Standalone)(Active)(/Common)(tmos)# bash
    [admin@ip-10-10-1-50:Active:Standalone] ~ #
```

## Deprovisioning Notes
It is important to delete the demo environment correctly using the deprovision script provided on the JumpHost. If resources are deleted in the incorrect order it is possible to leave orphaned objects in your AWS environment that could make deletion of the CFT challenging.

To deprovisioning your demo environment run the following command on the JumpHost
```bash
/var/tmp/deprovision_stack.sh
```

The deprovision script deletes the K8s environment and cleans up all artifacts associated to it and then deletes the CloudFormation Stack.

## Things to do
1. Add support for Bring Your Own Environment
1. Add support for infrastructure only deployments
1. Add support for Bring Your Own Licensed Big-IP
1. Add support for deployment to existing K8s environment

## Change Log
- 2.0 - updated to include support for nginx-plus-ingress and private docker registry
