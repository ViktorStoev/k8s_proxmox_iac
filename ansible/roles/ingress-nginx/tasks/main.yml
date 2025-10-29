---
- name: Install ingress-nginx (bare manifest)
  become: yes
  environment: { KUBECONFIG: /etc/kubernetes/admin.conf }
  command: >
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/cloud/deploy.yaml

- name: Wait for ingress controller
  become: yes
  environment: { KUBECONFIG: /etc/kubernetes/admin.conf }
  command: >
    kubectl -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=300s

