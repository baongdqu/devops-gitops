# 📚 BÍ KÍP TOÀN TẬP KIẾN THỨC DEVOPS & DEVSECOPS DỰ ÁN DÀNH CHO PHỎNG VẤN

> **Dự án:** *Automated Multi-Environment GitOps Deployment & Observability Platform*  
> **Mục đích:** Tài liệu học tập, ôn luyện và chuẩn bị phỏng vấn vị trí **DevOps Engineer / DevSecOps Engineer / SRE (Fresher / Junior / Middle)**.

---

## 📑 MỤC LỤC
1. [Tổng Quan Kiến Trúc & Luồng Dữ Liệu Thực Chiến](#1-tổng-quan-kiến-trúc--luồng-dữ-liệu-thực-chiến)
2. [Chi Tiết 6 Trụ Cột Kỹ Thuật Trong Dự Án](#2-chi-tiết-6-trụ-cột-kỹ-thuật-trong-dự-án)
   - [Trụ cột 1: Containerization & Docker Optimization](#trụ-cột-1-containerization--docker-optimization)
   - [Trụ cột 2: CI Pipeline & DevSecOps (GitHub Actions + Trivy)](#trụ-cột-2-ci-pipeline--devsecops-github-actions--trivy)
   - [Trụ cột 3: Kubernetes Orchestration & Kustomize Multienv](#trụ-cột-3-kubernetes-orchestration--kustomize-multienv)
   - [Trụ cột 4: GitOps Continuous Delivery (ArgoCD)](#trụ-cột-4-gitops-continuous-delivery-argocd)
   - [Trụ cột 5: Infrastructure as Code (Terraform)](#trụ-cột-5-infrastructure-as-code-terraform)
   - [Trụ cột 6: Observability, Metrics & Alerting (Prometheus, Grafana, Alertmanager)](#trụ-cột-6-observability-metrics--alerting)
3. [Bản Đồ Đối Chiếu File Trong Project Với Khái Niệm DevOps](#3-bản-đồ-đối-chiếu-file-trong-project-với-khái-niệm-devops)
4. [Bộ Câu Hỏi & Câu Trả Lời Phỏng Vấn DevOps Thực Chiến (Top 25+)](#4-bộ-câu-hỏi--câu-trả-lời-phỏng-vấn-devops-thực-chiến-top-25)
5. [Cẩm Nang Xử Lý Sự Cố Hệ Thống (Troubleshooting Runbook)](#5-cẩm-nang-xử-lý-sự-cố-hệ-thống-troubleshooting-runbook)
6. [Kịch Bản Thuyết Trình Dự Án Trước Nhà Tuyển Dụng](#6-kịch-bản-thuyết-trình-dự-án-trước-nhà-tuyển-dụng)

---

## 1. TỔNG QUAN KIẾN TRÚC & LUỒNG DỮ LIỆU THỰC CHIẾN

```
[ Developer ] 
     │ (git push commit SHA)
     ▼
[ GitHub Repository ] 
     │
     ├──► [ 1. CI Pipeline: GitHub Actions ]
     │         ├── Lint & Unit Test
     │         ├── DevSecOps: Trivy Scan (CVE vulnerability blocker)
     │         ├── Multi-Stage Docker Build
     │         └── Push Image -> GitHub Container Registry (GHCR)
     │
     └──► [ 2. GitOps Pipeline Update ]
               └── Auto-commit new Image SHA into `k8s/manifests/overlays/dev`
                      │
                      ▼
[ ArgoCD Controller ] ◄────── (Continuous Polling & Git Webhook)
     │ (Auto-sync & Self-heal)
     ▼
[ Kubernetes Cluster ]
     ├── Ingress Controller (Nginx Routing)
     ├── Frontend Pods (React + Nginx Runner)
     ├── Backend API Pods (Node.js Express + /metrics)
     ├── HPA (Horizontal Pod Autoscaler)
     └── Data Layer: PostgreSQL & Redis
            │
            ▼
[ Observability Stack ]
     ├── Prometheus (Scrape /metrics mỗi 15s)
     ├── Alertmanager (Bắn cảnh báo Telegram/Discord khi High Error Rate)
     └── Grafana (Dashboard trực quan 4 Golden Signals: Latency, Traffic, Errors, Saturation)
```

---

## 2. CHI TIẾT 6 TRỤ CỘT KỸ THUẬT TRONG DỰ ÁN

### Trụ cột 1: Containerization & Docker Optimization
1. **Multi-Stage Build Pattern**:
   - *Vấn đề thực tế:* Nếu dùng 1 image chứa cả Node SDK, build tools, source code, devDependencies thì image nặng 1GB - 2GB, chứa nhiều lỗ hổng và tốn băng thông pull/push.
   - *Giải pháp trong dự án:* Tách thành 2 stage:
     - `builder`: Dùng `node:20-alpine` để chạy `npm install` và `npm run build`.
     - `runner`: Chỉ dùng `nginx:alpine` siêu nhẹ (~20MB) và chỉ copy file artifact tĩnh từ builder sang. Image cuối cùng chỉ nặng ~30MB.
2. **Bảo mật Container Non-Root User**:
   - Chạy container bằng `USER appuser` (UID/GID khác 0) thay vì root mặc định. Nếu hacker khai thác lỗ hổng Remote Code Execution (RCE) trong app, chúng không thể chiếm quyền root trên Host Node.
3. **Docker Layer Caching & `.dockerignore`**:
   - Tách riêng bước `COPY package*.json` và `RUN npm install` trước khi `COPY . .` để tận dụng Docker cache layer khi source code thay đổi mà dependencies không đổi.
   - Dùng `.dockerignore` loại bỏ `node_modules`, `build`, `.git` giúp giảm context size từ hàng trăm MB xuống vài KB.

---

### Trụ cột 2: CI Pipeline & DevSecOps (GitHub Actions + Trivy)
1. **Shift-Left Security (Đưa bảo mật về sớm trong quy trình)**:
   - Thay vì đợi lên Production mới kiểm tra bảo mật (Penetration Test), ta tích hợp kiểm tra ngay trong CI mỗi khi tạo Pull Request.
2. **Quét lỗ hổng tự động với Trivy**:
   - Quét cả OS Packages (Alpine/Debian vulnerabilities) và Application Dependencies (NPM CVEs).
   - Thiết lập `exit-code: 1` và `severity: CRITICAL,HIGH` để chủ động làm FAIL pipeline, ngăn không cho image có lỗi bảo mật nghiêm trọng được phát hành.
3. **Immutability & Traceability (Tính bất biến và truy xuất nguồn gốc)**:
   - Không sử dụng tag `:latest` cho production vì `:latest` không thể hiện được code nào đang chạy và gây khó khăn khi rollback.
   - Sử dụng `Commit SHA` (`ghcr.io/username/app-backend:${{ github.sha }}`) làm image tag, đảm bảo mỗi bản build gắn liền chính xác với một commit trên Git.

---

### Trụ cột 3: Kubernetes Orchestration & Kustomize Multienv
1. **Quản lý Vòng Đời Ứng Dụng (Deployments & Pods)**:
   - Khai báo tài nguyên (`requests` và `limits` cho CPU/RAM) tránh hiện tượng "Noisy Neighbor" làm cạn kiệt tài nguyên node.
   - Chiến lược Zero-Downtime Deployment: `RollingUpdate` với `maxSurge: 25%` và `maxUnavailable: 0` giúp cập nhật phiên bản mới mà không rớt request nào của người dùng.
2. **Health Checks (Liveness & Readiness Probes)**:
   - `readinessProbe`: Kiểm tra `/api/health`. Nếu chưa sẵn sàng, K8s không route traffic tới Pod (tránh lỗi 502/503 khi app vừa khởi động).
   - `livenessProbe`: Nếu Backend bị deadlock/treo, K8s tự động kill và khởi động lại Pod mới.
3. **Kustomize (Base & Overlays Pattern)**:
   - Thư mục `base/`: Khai báo cấu hình chung (Deployment, Service, ConfigMap).
   - Thư mục `overlays/dev` và `overlays/prod`: Tùy biến replicas, tài nguyên (dev: 1 replica, prod: 3 replicas + HPA), environment variables theo từng môi trường mà không bị lặp code.

---

### Trụ cột 4: GitOps Continuous Delivery (ArgoCD)
1. **Push-based CI/CD vs Pull-based GitOps**:
   - *Mô hình truyền thống (Push)*: Server CI (Jenkins/GitHub Runner) phải giữ SSH Key hoặc Kubernetes Admin Kubeconfig để `kubectl apply`. Rủi ro lộ credential cụm K8s rất cao.
   - *Mô hình GitOps (Pull)*: ArgoCD cài đặt bên trong cluster, liên tục theo dõi Git Repository. Khi có commit mới, ArgoCD tự động "kéo" (pull) cấu hình về và áp dụng. Không cần mở cổng firewall vào Cluster.
2. **Self-Healing & Drift Detection**:
   - Nếu ai đó dùng lệnh `kubectl edit` hay `kubectl delete` trực tiếp trên cluster ngoài ý muốn (Configuration Drift), ArgoCD sẽ tự động phát hiện và khôi phục (Self-heal) về đúng cấu hình định nghĩa trên Git.

---

### Trụ cột 5: Infrastructure as Code (Terraform)
1. **Tính chất Khai báo (Declarative IaC)**:
   - Khai báo trạng thái mong muốn (Desired State) của hạ tầng trên AWS/Cloud.
   - Tự động tạo: VPC, Public/Private Subnets, Internet Gateway, NAT Gateway, Route Tables, Security Groups.
2. **Terraform State & Locking**:
   - Quản lý trạng thái hạ tầng trong `terraform.tfstate`.
   - Sử dụng S3 Remote Backend kết hợp DynamoDB Table để State Locking, ngăn 2 kỹ sư apply hạ tầng cùng lúc gây xung đột.

---

### Trụ cột 6: Observability, Metrics & Alerting
1. **Mô hình 4 Golden Signals (Google SRE Standard)**:
   - **Latency**: Thời gian xử lý request (Histogram buckets).
   - **Traffic**: Số lượng request trên giây (RPS - Counter metric).
   - **Errors**: Tỷ lệ request lỗi HTTP 5xx/4xx.
   - **Saturation**: Mức độ sử dụng CPU/RAM của hệ thống.
2. **Prometheus Architecture**:
   - Sử dụng cơ chế Pull-based để định kỳ kéo dữ liệu từ `/metrics` của backend.
3. **Alertmanager & PromQL Alerting**:
   - Viết câu lệnh PromQL: `rate(http_requests_total{status_code=~"5.."}[5m]) > 0.05` (Báo động khi lỗi 5xx vượt 5%).
   - Tự động kích hoạt Webhook gửi thông báo khẩn cấp đến Telegram/Discord/Slack.

---

## 3. BẢN ĐỒ ĐỐI CHIẾU FILE TRONG PROJECT VỚI KHÁI NIỆM DEVOPS

| Đường dẫn File / Thư mục | Chức năng kỹ thuật | Khái niệm DevOps / Phỏng vấn liên quan |
| :--- | :--- | :--- |
| `app/backend/Dockerfile` | Build Node.js API | Multi-stage build, Non-root user, Docker Layer Caching |
| `app/frontend/Dockerfile` | Build React & Nginx Host | Multi-stage build, Static content delivery, Reverse proxy |
| `app/docker-compose.yml` | Chạy full-stack local | Container Orchestration, Bridge Network, Data Volume |
| `.github/workflows/ci-backend.yml` | Pipeline CI Backend | CI Automation, Trivy Security Scan, GHCR Push |
| `.github/workflows/gitops-update.yml`| Cập nhật Image Tag GitOps | GitOps Automation, GitOps Pull Request/Commit flow |
| `k8s/manifests/base/` | K8s Manifests chuẩn | Declarative Manifests, ClusterIP, Liveness/Readiness Probe |
| `k8s/manifests/overlays/dev/` | Cấu hình K8s môi trường Dev | Kustomize Overlays, Resource Management |
| `gitops/argocd-apps/` | Khai báo ArgoCD App | GitOps Single Source of Truth, Auto-sync, Self-healing |
| `terraform/` | Khởi tạo AWS VPC & Subnets | Infrastructure as Code, VPC Architecture, Cloud Security |
| `monitoring/prometheus/` | Cấu hình Scrape & Alert Rules | Time Series DB, Prometheus Scraping, PromQL Alerts |
| `monitoring/alertmanager/` | Cấu hình nhận alert | Webhook Alerting, Incident Management, PagerDuty/Telegram |

---

## 4. BỘ CÂU HỎI & CÂU TRẢ LỜI PHỎNG VẤN DEVOPS THỰC CHIẾN (TOP 25+)

### 🔹 Phần 1: Docker & Container
**Q1: Multi-stage build trong Docker là gì và tại sao nên dùng?**  
*Trả lời:* Multi-stage build là kỹ thuật dùng nhiều chỉ thị `FROM` trong một Dockerfile duy nhất. Nó cho phép ta sử dụng một image đầy đủ công cụ (SDK, compilers) ở stage đầu để build source code, sau đó chỉ copy file artifact/binary đã build sang một stage runtime siêu nhẹ (như Alpine, Distroless). Lợi ích: Giảm kích thước image 80-90%, tăng tốc độ tải image, và giảm thiểu bề mặt tấn công bảo mật (Attack Surface).

**Q2: Làm sao để bảo mật một Docker Container khi chạy production?**  
*Trả lời:*  
1. Không chạy dưới quyền `root` (dùng `USER nonroot`).  
2. Sử dụng base image tối giản (Alpine/Distroless) và quét CVE định kỳ bằng Trivy.  
3. Đặt filesystem ở chế độ `read-only` nếu có thể.  
4. Giới hạn tài nguyên CPU/RAM để tránh DoS Host.  
5. Không hardcode Secrets/Passwords vào Dockerfile hoặc Image Layers.

---

### 🔹 Phần 2: CI/CD & DevSecOps
**Q3: DevSecOps khác DevOps truyền thống ở điểm nào?**  
*Trả lời:* DevOps truyền thống tập trung vào việc tự động hóa và tăng tốc độ phân phối phần mềm giữa Dev và Ops. DevSecOps tích hợp yếu tố **Bảo mật (Security)** vào toàn bộ chu trình ngay từ giai đoạn đầu (Shift-Left), tự động quét mã nguồn (SAST/DAST), quét dependencies (SCA) và quét container images (Trivy) trực tiếp trong CI/CD pipeline.

**Q4: Tại sao không nên dùng tag `:latest` khi deploy Kubernetes?**  
*Trả lời:*  
1. `:latest` không có tính bất biến (mutable), không biết chính xác commit code nào đang chạy.  
2. Kubernetes mặc định cache image nếu `imagePullPolicy` không phải `Always`, dẫn đến việc Pod mới có thể vẫn chạy code cũ.  
3. Gây bất khả thi khi muốn Rollback về phiên bản trước. Thay vào đó nên dùng Git Commit SHA hoặc Semantic Version (`v1.2.3`).

---

### 🔹 Phần 3: Kubernetes (K8s)
**Q5: Phân biệt Liveness Probe, Readiness Probe và Startup Probe?**  
*Trả lời:*  
- **Readiness Probe**: Xác định khi nào Pod sẵn sàng nhận traffic. Nếu fail, Pod bị loại khỏi Service endpoints (không nhận request), nhưng Pod không bị restart.  
- **Liveness Probe**: Xác định Pod còn sống hay đã bị treo/deadlock. Nếu fail, K8s sẽ kill và restart container.  
- **Startup Probe**: Dành cho các ứng dụng khởi động chậm, tạm thời vô hiệu hóa Liveness/Readiness cho đến khi app khởi động xong.

**Q6: Sự khác nhau giữa Kustomize và Helm Chart?**  
*Trả lời:*  
- **Helm**: Là Package Manager, dùng template engine (`{{ .Values.name }}`) để sinh manifest. Phù hợp cho việc đóng gói và chia sẻ ứng dụng cho bên thứ 3.  
- **Kustomize**: Là công cụ template-free (không dùng template), sử dụng nguyên lý overlay/patch đè lên file base YAML gốc. Kustomize được tích hợp sẵn trong `kubectl` (`kubectl -k`), cực kỳ phù hợp cho việc quản lý đa môi trường (dev, staging, prod) nội bộ trong GitOps.

---

### 🔹 Phần 4: GitOps & ArgoCD
**Q7: GitOps là gì? Trình bày 4 nguyên lý cốt lõi của GitOps?**  
*Trả lời:* GitOps là mô hình vận hành hệ thống trong đó Git là nguồn chân lý duy nhất (Single Source of Truth) cho cả hạ tầng và ứng dụng.  
4 nguyên lý:  
1. Toàn bộ hệ thống được mô tả bằng mã khai báo (Declarative).  
2. Trạng thái mong muốn (Desired State) được phiên bản hóa trên Git (Versioned & Immutable).  
3. Các thay đổi được tự động kéo và áp dụng (Automated Delivery/Pull-based).  
4. Liên tục đối soát và tự phục hồi khi có sai lệch (Continuous Reconciliation & Self-healing).

**Q8: Nếu một kỹ sư vô tình dùng `kubectl delete deployment` trực tiếp trên Cluster, ArgoCD sẽ xử lý thế nào?**  
*Trả lời:* Nếu bật tính năng `Self-Healing` trong ArgoCD Application, ArgoCD sẽ ngay lập tức phát hiện trạng thái thực tế (Live State) bị lệch so với khai báo trên Git (Target State) và tự động tạo lại Deployment đó ngay lập tức để đồng bộ.

---

### 🔹 Phần 5: Observability & SRE
**Q9: Prometheus thu thập metrics theo cơ chế Push hay Pull? Ưu điểm là gì?**  
*Trả lời:* Prometheus chủ yếu sử dụng cơ chế **Pull** (server định kỳ gửi HTTP request đến endpoint `/metrics` của target để cào dữ liệu).  
*Ưu điểm:*  
- Dễ dàng kiểm soát tần suất scrape (không bị ngập lụt dữ liệu nếu target gửi quá nhiều).  
- Dễ phát hiện service nào bị chết (nếu Pull fail -> Service Down ngay lập tức).  
- Không cần cài agent phức tạp trên ứng dụng.

---

## 5. CẨM NANG XỬ LÝ SỰ CỐ HỆ THỐNG (TROUBLESHOOTING RUNBOOK)

Khi người phỏng vấn hỏi: *"Hãy kể về một lần em debug sự cố trên Kubernetes?"*, bạn hãy dùng quy trình chuẩn sau:

```
                  [ Báo Động / Lỗi ]
                          │
            ┌─────────────┴─────────────┐
            ▼                           ▼
[ 1. Kiểm tra Pod Status ]     [ 2. Kiểm tra Logs ]
  kubectl get pods -n <ns>       kubectl logs <pod-name> --previous
            │                           │
            ▼                           ▼
[ 3. Xem Chi Tiết Sự Kiện ]    [ 4. Kiểm tra Tài Nguyên & Mạng ]
  kubectl describe pod <pod>     kubectl top pods / exec curl test
```

### Các mã lỗi kinh điển và cách xử lý:
1. **CrashLoopBackOff**:  
   - *Nguyên nhân:* Ứng dụng bị lỗi unhandled exception, thiếu biến môi trường, hoặc kết nối database thất bại ngay khi khởi động.  
   - *Cách fix:* `kubectl logs <pod-name>` để xem log crash; kiểm tra lại `ConfigMap` và `Secret`.
2. **OOMKilled (Exit Code 137)**:  
   - *Nguyên nhân:* Pod sử dụng bộ nhớ RAM vượt quá mức `limits.memory` đã khai báo.  
   - *Cách fix:* Tăng memory limit trong manifest hoặc kiểm tra memory leak trong code backend.
3. **ImagePullBackOff / ErrImagePull**:  
   - *Nguyên nhân:* Sai tên image tag, image chưa được push lên registry, hoặc thiếu `imagePullSecrets` để xác thực private registry.
4. **Pending Pod**:  
   - *Nguyên nhân:* Cluster hết tài nguyên CPU/RAM để gán cho Pod, hoặc không thỏa mãn Node Selector / Affinity.

---

## 6. KỊCH BẢN THUYẾT TRÌNH DỰ ÁN TRƯỚC NHÀ TUYỂN DỤNG

### ⏱️ Bản tóm tắt 3 phút (Elevator Pitch):
> *"Chào anh/chị, em xin giới thiệu dự án tâm huyết của em: **Automated Multi-Environment GitOps & Observability Platform**.  
> Đây là nền tảng DevOps chuẩn hóa cho ứng dụng 3-Tier. Trong dự án này:
> 1. **Về CI/DevSecOps**: Em dùng GitHub Actions tự động hóa kiểm thử, quét lỗ hổng CVE với Trivy và build Docker image tối ưu chuẩn Multi-stage Non-root.  
> 2. **Về GitOps & CD**: Em ứng dụng mô hình Pull-based với ArgoCD kết hợp Kustomize để tự động đồng bộ cấu hình đa môi trường lên Kubernetes mà không cần cấp quyền nhạy cảm cho CI.  
> 3. **Về Giám Sát**: Em xây dựng hệ thống Observability với Prometheus và Grafana để theo dõi 4 Golden Signals, kèm Alertmanager tự động cảnh báo sự cố về Telegram.  
> Dự án giúp em nắm vững toàn bộ vòng đời phân phối phần mềm từ code đến production theo chuẩn tự động, an toàn và có độ tin cậy cao."*
