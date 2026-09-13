# 🧪 KỊCH BẢN TEST: TÁCH BIỆT CẤU HÌNH ĐA MÔI TRƯỜNG DEV VÀ PROD (KUBERNETES KUSTOMIZE OVERLAYS)

## 📌 1. Mục đích thử nghiệm
Kiểm chứng nguyên lý **"Don't Repeat Yourself (DRY) & Configuration Overlay"** của Kubernetes Kustomize:
* **Vấn đề thực tế:** 
  - Môi trường **Development (Dev)**: Cần tiết kiệm chi phí, chỉ chạy 1-2 Pods, dùng image phiên bản mới nhất (`latest`), nằm ở phân vùng an toàn để lập trình viên quậy phá thử nghiệm.
  - Môi trường **Production (Prod)**: Cần độ tin cậy tuyệt đối, chạy tối thiểu **4 Pods**, dùng image phiên bản cố định có gắn tag cụ thể (`v1.0.0`), đặt nhãn riêng để phục vụ khách hàng thật.
  - *Nếu copy-paste thành 2 bộ file riêng biệt thì khi sửa code rất dễ bị sót lỗi hoặc sai lệch cấu hình.*
* **Giải pháp Kustomize:** Giữ nguyên **1 bộ khung chuẩn duy nhất (`base/`)**, và dùng các lớp phủ **`overlays/dev`** và **`overlays/prod`** để tự động đè các thông số tương ứng theo từng môi trường.

---

## ⚙️ 2. Đối chiếu cấu hình thực tế trong dự án

```
                             📁 k8s/manifests/base/ (Bộ khung chuẩn)
                                       │
                ┌──────────────────────┴──────────────────────┐
                ▼                                             ▼
    📁 overlays/dev/ (Môi trường Dev)             📁 overlays/prod/ (Môi trường Prod)
    • Namespace: `dev`                           • Namespace: `prod`
    • Tiền tố tên: `dev-`                         • Tiền tố tên: `prod-`
    • Số lượng Pods: 2                           • Số lượng Pods: 4 (Tự động ghi đè)
    • Phiên bản Image: `:latest`                 • Phiên bản Image: `:v1.0.0`
```

---

## 🚀 3. Các bước thực hiện thử nghiệm chi tiết (Xem Kustomize sinh mã tự động)

Bạn **không cần phải áp dụng làm loạn cluster**, Kustomize cho phép bạn "soi" trước bản vẽ cấu hình của từng môi trường bằng lệnh `kubectl kustomize`:

### 🔹 Bước 1: Soi cấu hình của môi trường DEV
Mở PowerShell và gõ:
```powershell
kubectl kustomize k8s/manifests/overlays/dev | Select-String -Pattern "namespace:|name: dev-|replicas:"
```

👀 **Kết quả Kustomize tự động sinh ra cho Dev:**
* Phân vùng: `namespace: dev`
* Tên ứng dụng được gắn tiền tố: `name: dev-backend`, `name: dev-frontend`
* Số bản sao: `replicas: 2`

---

### 🔹 Bước 2: Soi cấu hình của môi trường PROD
Gõ tiếp lệnh kiểm tra môi trường Prod:
```powershell
kubectl kustomize k8s/manifests/overlays/prod | Select-String -Pattern "namespace:|name: prod-|replicas:"
```

👀 **Kết quả Kustomize tự động biến đổi cho Prod:**
* Phân vùng tách biệt hoàn toàn: `namespace: prod`
* Tên ứng dụng được bảo vệ riêng: `name: prod-backend`, `name: prod-frontend`
* **Số lượng Pods tự động tăng vọt lên 4 Pods (`replicas: 4`)** để gánh tải khách hàng thật!

---

### 🔹 Bước 3: Triển khai thực tế thử 1 môi trường (Nếu muốn)
Chỉ với 1 dòng lệnh:
```powershell
# Tạo namespace dev trước:
kubectl create namespace dev

# Triển khai toàn bộ hệ thống Dev:
kubectl apply -k k8s/manifests/overlays/dev
```
Kiểm tra:
```powershell
kubectl get pods -n dev
```
Bạn sẽ thấy các Pod mang tên `dev-backend-...` và `dev-frontend-...` xuất hiện tách biệt hoàn toàn trong phân vùng `dev`!

---

### 💡 Bài học giá trị nhất của Kustomize trong DevOps:
* Lập trình viên chỉ cần duy trì đúng **1 bộ mã nguồn gốc** trong `base/`.
* Khi đẩy lên Git, công cụ **ArgoCD (GitOps)** sẽ tự động trỏ:
  - Nhánh `develop` ➜ Kéo cấu hình `overlays/dev`
  - Nhánh `main` ➜ Kéo cấu hình `overlays/prod`
👉 Quá trình triển khai đa môi trường diễn ra hoàn toàn tự động, minh bạch và không bao giờ có rủi ro con người cấu hình nhầm!
