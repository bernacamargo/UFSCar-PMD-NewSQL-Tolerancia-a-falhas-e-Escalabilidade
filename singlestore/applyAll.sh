kubectl apply -f operator/rbac.yaml
kubectl apply -f operator/singlestore-cluster-crd.yaml
kubectl apply -f operator/deploy.yaml
kubectl apply -f operator/singlestore-cluster.yaml