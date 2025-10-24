

# Kubernetes Cluster on Proxmox with Terraform + Ansible

**k8s-proxmox-iac** — это полностью автоматизированный проект, демонстрирующий развёртывание производственного Kubernetes-кластера на инфраструктуре **Proxmox VE** с помощью **Terraform** и **Ansible**.

На текущем этапе реализовано:
- Автоматическое создание виртуальных машин на Proxmox через Terraform  
- Настройка Kubernetes-кластера (1 control plane + 2 worker) с помощью Ansible  
- Установка сетевого плагина **Calico (v3.30.3)**  
- Установка балансировщика **MetalLB (v0.14.5)** с L2-advertisement  

---

## Архитектура проекта

```bash
k8s-proxmox-iac/
├─ terraform/                     # Создание ВМ в Proxmox
│  ├─ main.tf
│  ├─ variables.tf
│  ├─ outputs.tf
│  └─ terraform.tfvars (в .gitignore)
│
├─ ansible/
│  ├─ inventory/
│  │   ├─ inventory.ini           # сгенерированные IP-адреса ВМ
│  │   └─ ssh_config              # сгенерированный SSH-конфиг для Ansible
│  ├─ group_vars/
│  │   └─ all.yml                 # Общие переменные (версии, сети, MetalLB-pool)
│  ├─ roles/
│  │   ├─ common/                 # Базовые настройки ОС
│  │   ├─ kubeadm-init/           # Инициализация control plane
│  │   ├─ join-workers/           # Присоединение worker-нод
│  │   ├─ calico/                 # Установка Calico CNI
│  │   └─ metallb/                # Установка MetalLB (L2 mode)
│  │   
│  └─ playbook.yml                    # Основной playbook
│
├─ scripts/
│  └─ smoke-test.sh               # Проверка готовности кластера и LB
│
├─ .github/
│  └─ workflows/
│      └─ ci.yml                  # CI: terraform validate, ansible-lint
│
└─ README.md
````

---

## Используемые технологии

| Компонент                        | Назначение                                          |
| -------------------------------- | --------------------------------------------------- |
| **Terraform**                    | Автоматизация создания виртуальных машин на Proxmox |
| **Ansible**                      | Конфигурация Kubernetes-нод, установка компонентов  |
| **Kubernetes v1.34.1**           | Контейнерная оркестрация                            |
| **Calico v3.30.3**               | Сетевой плагин (CNI), поддержка NetworkPolicy       |
| **MetalLB v0.14.5**              | L2-балансировщик для Service типа LoadBalancer      |
| **Ubuntu 22.04 LTS**             | ОС для всех нод                                     |
| **Proxmox VE 8.x**               | Платформа виртуализации                             |
| **YAML, Jinja2, GitHub Actions** | IaC, шаблонизация, CI                               |

---

## Подготовка окружения

1️⃣ **Установите зависимости** на хосте, где будет запускаться IaC:

```bash
sudo apt install terraform ansible sshpass python3-proxmoxer -y
```

2️⃣ **Скопируйте `terraform.tfvars.example` → `terraform.tfvars`**
и укажите параметры подключения к Proxmox:

```hcl
proxmox_url    = "https://192.168.1.10:8006/api2/json"
proxmox_user   = "root@pam"
proxmox_token_id     = "terraform"
proxmox_token_secret = "xxxxx"
vm_count      = 3
vm_name       = "k8s-ubuntu"
vm_template   = "ubuntu-cloudinit-template"
```

3️⃣ **Запустите создание ВМ**

```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

4️⃣ **Проверьте доступность ВМ**

```bash
cd ansible
ansible all -i ansible/inventory/inventory.ini -m ping
```

5️⃣ **Разверните кластер**

```bash
cd ansible
ansible-playbook -i inventory/inventory.ini playbook.yml
```

---

## Что делает playbook

Выполняется последовательная установка и настройка:

1. Отключение swap, настройка `sysctl`, включение ip_forward
2. Установка Containerd, kubeadm/kubectl/kubelet
3. `kubeadm init` на control plane
4. Присоединение worker-нод
5. Установка Calico (сетевой CNI)
6. Установка MetalLB с L2-advertisement


---

## Smoke-тест

После успешного выполнения плейбука:

```bash
# Проверка статуса нод
kubectl get nodes -o wide

# Проверка Calico и MetalLB
kubectl -n calico-system get pods
kubectl -n metallb-system get pods

# Проверка демо-сервиса
kubectl create ns demo
kubectl -n demo create deploy web --image=nginx
kubectl -n demo expose deploy web --port=80 --type=LoadBalancer
kubectl -n demo get svc web -o wide
```

Пример успешного вывода:

```
NAME   TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)        AGE
web    LoadBalancer   10.98.27.223   192.168.1.240   80:31319/TCP   2m
```

Проверка доступа:

```bash
curl http://192.168.1.240
```

Результат:

```
Welcome to nginx!
```

---


## 👨‍💻 Автор проекта

**Виктор Стоев**
DevOps Engineer
📍 Russia
🔗 GitHub: [ViktorStoev](https://github.com/ViktorStoev)

---
