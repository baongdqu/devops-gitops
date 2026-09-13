# 🚀 Multi-Environment Production GitOps & Infrastructure Platform

Repository trung tâm quản lý toàn bộ cấu hình triển khai **Production / Staging / Dev**, Hạ tầng đám mây (IaC) và Hệ thống Giám sát vận hành (Observability) theo chuẩn Enterprise GitOps.

---

## 📁 Cấu trúc thư mục

```
project devops gitops/
├── k8s/manifests/                # Kubernetes Manifests (Kustomize)
│   ├── base/                     # Deployment, Service, Ingress, HPA, ConfigMap
│   └── overlays/                 # dev & prod environments
├── gitops/argocd-apps/           # Khai báo ArgoCD Applications (Auto-sync & Self-heal)
│   ├── dev-app.yaml
│   └── prod-app.yaml
├── terraform/                    # Infrastructure as Code (AWS VPC, Subnets, SG)
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── monitoring/                   # Observability & Alerting Stack
│   ├── prometheus/               # Cấu hình Scrape & Alert Rules
│   ├── alertmanager/             # Cấu hình Bắn Alert Telegram/Discord
│   └── docker-compose.monitoring.yml # Dựng Prometheus + Grafana + Alertmanager
├── DEVOPS_GUIDE.md               # Sách lược và tài liệu hướng dẫn phỏng vấn
└── DEVOPS_INTERVIEW_KNOWLEDGE_BASE.md
```

---

## ☸️ Triển khai Kubernetes Manifests (Kustomize)

### 1. Xem trước cấu hình môi trường Dev:
```bash
kubectl kustomize k8s/manifests/overlays/dev
```

### 2. Xem trước cấu hình môi trường Production (4 Replicas, High Availability):
```bash
kubectl kustomize k8s/manifests/overlays/prod
```

### 3. Áp dụng triển khai trực tiếp:
```bash
kubectl apply -k k8s/manifests/overlays/dev
# Hoặc áp dụng môi trường Production
kubectl apply -k k8s/manifests/overlays/prod
```

---

## 🐙 Quản lý bằng GitOps (ArgoCD)
ArgoCD theo dõi trực tiếp repository này để đảm bảo trạng thái trên Cluster luôn khớp 100% với Git:
* `gitops/argocd-apps/dev-app.yaml`
* `gitops/argocd-apps/prod-app.yaml`
Cơ chế **Self-Heal** và **Auto-Sync** được kích hoạt tự động.
