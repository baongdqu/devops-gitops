# 🧪 KỊCH BẢN TEST: NẠP BIẾN MÔI TRƯỜNG KHÔNG CẦN BUILD LẠI CODE (KUBERNETES CONFIGMAP)

## 📌 1. Mục đích thử nghiệm
Kiểm chứng nguyên lý cốt lõi **"12-Factor App / Configuration Separation"** trong DevOps:
* **Vấn đề truyền thống:** Mỗi lần muốn đổi cấu hình (đổi chế độ `development` sang `production`, đổi chuỗi kết nối, đổi thông điệp chào mừng), lập trình viên phải sửa code rồi ngồi chờ 5-10 phút để compile, build lại Docker Image và deploy lại từ đầu.
* **Giải pháp Kubernetes (ConfigMap):** K8s tách biệt hoàn toàn mã nguồn (Code) và Cấu hình (Config). Bạn có thể thay đổi biến môi trường bất cứ lúc nào, K8s sẽ **tự động tiêm (Inject) giá trị mới vào container mà không cần đụng vào 1 dòng code hay build lại Docker image**!

---

## ⚙️ 2. Cơ chế đã cấu hình trong dự án

* **File lưu trữ biến môi trường:** [k8s/manifests/base/ingress-hpa-config.yaml](file:///c:/Users/s3cr3t/Desktop/phần%20mềm%20devops/k8s/manifests/base/ingress-hpa-config.yaml):
  ```yaml
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: app-config
  data:
    PORT: "5000"
    NODE_ENV: "production"
    APP_MESSAGE: "Xin chao DevOps Cloud-Native!"  # <-- Chúng ta sẽ đổi biến này
  ```
* **File Pod tiêu thụ biến môi trường:** [k8s/manifests/base/backend.yaml](file:///c:/Users/s3cr3t/Desktop/phần%20mềm%20devops/k8s/manifests/base/backend.yaml):
  ```yaml
  envFrom:
    - configMapRef:
        name: app-config   # Tự động nạp toàn bộ key-value trong app-config vào OS môi trường
  ```

---

## 🚀 3. Các bước thực hiện thử nghiệm chi tiết

### 🔹 Bước 1: Kiểm tra giá trị biến môi trường hiện tại bên trong Pod
Mở PowerShell và in ra danh sách biến môi trường thực tế đang chạy bên trong 1 Pod Backend:
```powershell
kubectl exec deployment/backend -- printenv NODE_ENV
```
*Kết quả:*
```text
production
```

---

### 🔹 Bước 2: Thay đổi biến môi trường trực tiếp trong K8s (Không cần build code!)
Bạn chỉ cần dùng 1 lệnh duy nhất để cập nhật thêm một biến môi trường mới toanh (ví dụ `APP_FEATURE_FLAG=ENABLED` hoặc đổi `NODE_ENV=staging`):

```powershell
kubectl patch configmap app-config -p '{\"data\":{\"NODE_ENV\":\"staging\",\"FEATURE_MAINTENANCE\":\"TRUE\"}}'
```

*Kiểm tra xem ConfigMap đã đổi chưa:*
```powershell
kubectl get configmap app-config -o yaml
```
*Bạn sẽ thấy giá trị đã lập tức được lưu vào Kubernetes:*
```yaml
data:
  NODE_ENV: staging
  FEATURE_MAINTENANCE: "TRUE"
  PORT: "5000"
```

---

### 🔹 Bước 3: Áp dụng cấu hình mới cho Pods trong 1 giây (Rolling Restart)
Chỉ cần yêu cầu K8s nạp lại cấu hình:
```powershell
kubectl rollout restart deployment/backend
```
> *(Không tốn dù chỉ 1 giây để build lại image! K8s chỉ đơn giản khởi động lại các Pod và tự động nhúng giá trị mới vào).*

---

### 🔹 Bước 4: Kiểm tra thành quả
Sau 5 giây, kiểm tra lại biến môi trường bên trong Pod mới:
```powershell
kubectl exec deployment/backend -- printenv NODE_ENV
```
*Kết quả:*
```text
staging
```
Và kiểm tra biến mới:
```powershell
kubectl exec deployment/backend -- printenv FEATURE_MAINTENANCE
```
*Kết quả:*
```text
TRUE
```

---

### 💡 Bài học giá trị trong DevOps:
Nhờ có **ConfigMap**, cùng một Docker Image `devops-backend` bạn có thể mang đi chạy ở:
- **Môi trường Dev:** Gắn ConfigMap `NODE_ENV=development`
- **Môi trường Test:** Gắn ConfigMap `NODE_ENV=testing`
- **Môi trường Production:** Gắn ConfigMap `NODE_ENV=production`
👉 **Build một lần – Triển khai khắp mọi nơi (Build Once, Run Anywhere)!**
