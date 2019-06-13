# Create a generic Secret containing your BIG-IP login information.
* This should be done after creation of the bigip-ingress namespace
```bash
    kubectl create secret generic bigip-login --namespace bigip-ingress --from-literal=username=admin --from-literal=password=admin
```
