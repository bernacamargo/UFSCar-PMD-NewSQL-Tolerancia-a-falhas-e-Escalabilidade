kubectl delete -f ../operator/singlestore-cluster.yaml
kubectl delete -f ../operator/deploy.yaml
kubectl delete -f ../operator/singlestore-cluster-crd.yaml
kubectl delete -f ../operator/rbac.yaml
kubectl delete svc svc-memsql-cluster-ddl
kubectl delete pvc --all