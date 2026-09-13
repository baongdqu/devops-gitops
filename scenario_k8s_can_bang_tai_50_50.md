# 🧪 KỊCH BẢN TEST: CÂN BẰNG TẢI CHIA ĐỀU 50/50 (KUBERNETES SERVICE LOAD BALANCING)

## 📌 1. Mục đích thử nghiệm
Kiểm chứng tính năng **Cân bằng tải nội bộ (Internal Load Balancer - Round-Robin)** của Kubernetes Service:
* **Vấn đề thực tế:** Bạn có 2 Pod Backend (`Pod A` và `Pod B`) chạy song song. Làm sao để đảm bảo các yêu cầu từ khách hàng được **chia đều cho cả 2 máy**, tránh trường hợp Pod A làm việc kiệt sức còn Pod B ngồi chơi?
* **Cơ chế hoạt động của K8s:** `Service/backend-service` đóng vai trò là một đầu mối giao tiếp duy nhất. Khi nhận các request liên tiếp, K8s sẽ luân phiên phân phối:
  - Request 1 ➜ Đi vào **Pod A**
  - Request 2 ➜ Đi vào **Pod B**
  - Request 3 ➜ Đi vào **Pod A**
  - Request 4 ➜ Đi vào **Pod B**
  *(Tỷ lệ chia tải tiệm cận chuẩn xác 50% - 50%)*.

---

## ⚙️ 2. Cấu hình Service trong mã nguồn
Trong file [k8s/manifests/base/backend.yaml](file:///c:/Users/s3cr3t/Desktop/phần%20mềm%20devops/k8s/manifests/base/backend.yaml):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP       # Cấp 1 IP ảo nội bộ đại diện cho cả 2 Pods
  ports:
    - port: 5000
  selector:
    app: backend        # Tự động gom tất cả các Pods có nhãn 'app: backend' vào cụm cân bằng tải
```

---

## 🚀 3. Các bước thực hiện thử nghiệm chi tiết

### 🔹 Bước 1: Kiểm tra 2 Pods Backend đang phục vụ
Mở PowerShell, gõ lệnh:
```powershell
kubectl get pods -l app=backend
```
**Kết quả mẫu:**
```text
NAME                      READY   STATUS    RESTARTS   AGE
backend-cf6575595-lgrbg   1/1     Running   0          2m   <-- Giả sử là Pod A
backend-cf6575595-zsvkm   1/1     Running   0          2m   <-- Giả sử là Pod B
```

---

### 🔹 Bước 2: Bắn liên tiếp 6 Requests vào `backend-service`
Chạy một lệnh lặp gửi 6 request liên tiếp vào địa chỉ dịch vụ của K8s:

```powershell
1..6 | ForEach-Object { kubectl exec deployment/frontend -- wget -qO- http://backend-service:5000/api/health; Write-Host "" }
```

---

### 🔹 Bước 3: Quan sát K8s chia đều tải 50/50 qua trường `"pod"`
Bạn sẽ nhận được 6 dòng kết quả phản hồi từ server, trong đó mỗi Pod sẽ **báo danh tên định danh duy nhất của mình**:

```json
{"status":"UP","pod":"backend-cf6575595-lgrbg","timestamp":"..."}  <-- Request 1 vào Pod A
{"status":"UP","pod":"backend-cf6575595-zsvkm","timestamp":"..."}  <-- Request 2 vào Pod B
{"status":"UP","pod":"backend-cf6575595-lgrbg","timestamp":"..."}  <-- Request 3 vào Pod A
{"status":"UP","pod":"backend-cf6575595-zsvkm","timestamp":"..."}  <-- Request 4 vào Pod B
{"status":"UP","pod":"backend-cf6575595-lgrbg","timestamp":"..."}  <-- Request 5 vào Pod A
{"status":"UP","pod":"backend-cf6575595-zsvkm","timestamp":"..."}  <-- Request 6 vào Pod B
```

👀 **Kết quả phân tích:**
* Tổng số request: **6**
* Số request do **Pod A (`lgrbg`)** xử lý: **3 (50%)**
* Số request do **Pod B (`zsvkm`)** xử lý: **3 (50%)**

👉 **Tỷ lệ chia tải chính xác 50/50 hoàn hảo!**

---

### 💡 Bước 4: Test nâng cao khi có 5 Pods (Auto-scaling)
Nếu bạn scale hệ thống lên 5 Pods (`kubectl scale deployment/backend --replicas=5`), Service sẽ ngay lập tức tự động nhận diện cả 5 Pods và chia đều **20% lượt truy cập cho mỗi Pod** mà bạn không cần phải cấu hình lại mạng hay khởi động lại bất kỳ dịch vụ nào!
