### Deploy simple

```sh
kubectl create -f simple.yaml
```

### Deploy envoy

```sh
kubectl create configmap envoy-config --from-file=envoy.yaml
kubectl create -f envoy-deploy.yaml
```

// Didn't find a registered implementation for 'envoy.filters.http.router' with type URL:'