kubectl apply -f ./rbac.yaml
kubectl apply -f ./singlestore-cluster-crd.yaml
kubectl apply -f ./deploy.yaml
kubectl apply -f ./singlestore-cluster.yaml