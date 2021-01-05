kubectl apply -f ./operator-rbac.yaml
kubectl apply -f ./operator-crd.yaml
kubectl apply -f ./operator-deploy.yaml
kubectl apply -f ./cockroachdb-cluster.yaml