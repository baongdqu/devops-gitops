# 🧪 KỊCH BẢN TEST: ĐIỀU HƯỚNG CỔNG ROUTER THÔNG MINH (KUBERNETES INGRESS / VÀ /API)

## 📌 1. Mục đích thử nghiệm
Kiểm chứng tính năng **Ingress Controller (API Gateway / Router thông minh)** của Kubernetes:
* **Vấn đề trong Microservices:** Ứng dụng có cả trăm dịch vụ nhỏ (Frontend port 80, Backend port 5000, Auth port 4000...). Người dùng không thể nhớ từng cổng lằng nhằng như `:3000`, `:5000` để truy cập.
* **Giải pháp Ingress:** Cung cấp **MỘT TÊN MIỀN DUY NHẤT** (`http://devops.local`) và tự động phân luồng:
  - Khi người dùng vào trang chủ **`/`** ➜ K8s tự động bẻ lái sang **Frontend (React)**.
  - Khi gọi dữ liệu **`/api/*`** ➜ K8s tự động bẻ lái sang **Backend (Node.js API)**.

---

## ⚙️ 2. Cấu hình Ingress đã thiết lập trong mã nguồn
Trong file [k8s/manifests/base/ingress-hpa-config.yaml](file:///c:/Users/s3cr3t/Desktop/phần%20mềm%20devops/k8s/manifests/base/ingress-hpa-config.yaml):
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
spec:
  rules:
    - host: devops.local
      http:
        paths:
          - path: /api      # Bắt đầu bằng /api -> Chuyển vào backend-service:5000
            pathType: Prefix
            backend:
              service:
                name: backend-service
                port:
                  number: 5000
          - path: /         # Mọi đường dẫn còn lại -> Chuyển vào frontend-service:80
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 80
```

---

## 🚀 3. Các bước thực hiện thử nghiệm chi tiết

### 🔹 Bước 1: Mở cổng Ingress thử nghiệm (Port-forward)
Trong môi trường Docker Desktop / KinD local, để mở cầu nối từ máy tính vào Ingress Controller, bạn mở một cửa sổ PowerShell và chạy:
```powershell
kubectl port-forward service/app-ingress 8080:80
```
*(Nếu muốn test trực tiếp qua Service của từng thành phần, bạn có thể kiểm chứng luồng phân nhánh của K8s)*.

Hoặc cách test chuẩn xác nhất ngay trên mạng nội bộ của cụm K8s:

---

### 🔹 Bước 2: Test điều hướng vào Frontend (`/`)
Mở một cửa sổ terminal khác và gửi request tới đường dẫn gốc `/`:
```powershell
kubectl run test-curl --rm -i --tty --image=curlimages/curl --restart=Never -- curl -s http://frontend-service:80/ | head -n 10
```
**Kết quả thực tế:**
* Bạn sẽ nhận được mã HTML gốc của **React Frontend Web** (`<!DOCTYPE html>`, `<title>React App</title>`).
👉 K8s đã chuyển đúng vào giao diện Web!

---

### 🔹 Bước 3: Test điều hướng vào Backend API (`/api/todos`)
Gửi request có tiền tố `/api`:
```powershell
kubectl run test-curl --rm -i --tty --image=curlimages/curl --restart=Never -- curl -s http://backend-service:5000/api/todos
```
**Kết quả thực tế:**
* Bạn sẽ nhận được chuỗi dữ liệu JSON của **Node.js Backend**:
```json
{"success":true,"data":[{"id":1,"title":"Learn Docker & Kubernetes","completed":true}...]}
```
👉 K8s đã chuyển đúng vào bộ não API!

---

### 🔹 Bước 4: Test thử nghiệm bằng trình duyệt Web trên Windows
Nếu bạn muốn gõ chữ **`http://devops.local`** trực tiếp trên trình duyệt Chrome/Edge của mình:
1. Mở file `C:\Windows\System32\drivers\etc\hosts` bằng quyền Administrator.
2. Thêm dòng:
   ```text
   127.0.0.1 devops.local
   ```
3. Lưu lại và mở trình duyệt:
   - Truy cập: `http://devops.local/` ➜ Hiển thị web React.
   - Truy cập: `http://devops.local/api/health` ➜ Hiển thị JSON `{"status":"UP"}`.

---

### 💡 Bài học giá trị:
Nhờ có **Ingress**:
* Hệ thống của bạn chỉ cần **1 địa chỉ IP công khai duy nhất** và **1 chứng chỉ SSL (HTTPS)** duy nhất.
* Người dùng bên ngoài hoàn toàn không biết phía sau có bao nhiêu chục container và chúng đang chạy trên những cổng nào, giúp hệ thống cực kỳ an toàn và chuyên nghiệp!
