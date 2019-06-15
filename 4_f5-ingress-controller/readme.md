# Create a generic Secret containing your BIG-IP login information.
## This should be done after creation of the bigip-ingress namespace
```bash
    kubectl create secret generic bigip-login -n bigip-ingress --from-literal=username=bigip-ingress --from-literal=password=BIGIPIngressController123
```
## Modifying the k8s secret after it is created
```bash
    kubectl patch secret bigip-login -p='{"data":{"password": "$(echo Admin123!@# | base64)"}}' -v=1

    kubectl get secret bigip-login -n bigip-ingress -o json | jq --arg foo "$(echo -n Admin123 | base64)" '.data["password"]=$foo' | kubectl apply -f -

    tmsh create auth user bigip-ingress partition-access add { all-partitions  { role admin } } password BIGIPIngressController123
```

## Create service account
```bash
    kubectl create serviceaccount bigip-ctlr -n bigip-ingress
```
