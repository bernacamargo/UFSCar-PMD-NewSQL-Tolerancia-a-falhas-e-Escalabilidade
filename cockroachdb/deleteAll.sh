kubectl delete -f ./operator-rbac.yaml
kubectl delete -f ./operator-crd.yaml
kubectl delete -f ./operator-deploy.yaml
kubectl delete -f ./cockroachdb-cluster.yaml
kubectl delete pvc --all
kubectl delete pv --all