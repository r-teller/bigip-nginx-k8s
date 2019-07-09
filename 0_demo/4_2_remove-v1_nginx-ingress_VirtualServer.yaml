apiVersion: k8s.nginx.org/v1alpha1
kind: VirtualServer
metadata:
  name: financial-reporting
spec:
  host: reporting.acmefinancial.net
  upstreams:
  - name: financial-reporting-v2
    service: financial-reporting-v2-svc
    port: 80
  routes:
  - path: /
    upstream: financial-reporting-v2
