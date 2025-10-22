set -e
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl create ns demo || true
kubectl -n demo create deploy web --image=nginx || true
kubectl -n demo expose deploy web --port=80 --type=LoadBalancer || true
kubectl -n demo get svc web -o wide

