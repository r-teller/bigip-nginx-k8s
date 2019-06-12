Deploying k8s in AWS
* https://github.com/kubernetes/kops/blob/master/docs/aws.md

k8s cheat sheet
* https://kubernetes.io/docs/reference/kubectl/cheatsheet/

install nginx-ingress controller
* https://github.com/nginxinc/kubernetes-ingress/blob/master/docs/installation.md

nginx example app
* https://github.com/nginxinc/kubernetes-ingress/tree/master/examples/complete-example

f5 & k8s ingress controller
* https://clouddocs.f5.com/containers/v2/kubernetes/kctlr-app-install.html

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
