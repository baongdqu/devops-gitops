# 🧪 KỊCH BẢN TEST: KHỐNG CHẾ TRẦN RAM 256MB CHỐNG TRÀN BỘ NHỚ (OOMKILLED)

## 📌 1. Mục đích thử nghiệm
Kiểm chứng cơ chế **Resource Limits & OOMKilled (Out Of Memory Killed)** của Kubernetes:
* Trong các ứng dụng thực tế, lập trình viên rất dễ mắc lỗi rò rỉ bộ nhớ (**Memory Leak** - ví dụ: nhồi dữ liệu vào mảng không giải phóng, hoặc xử lý file upload quá lớn).
* Nếu không có Kubernetes bảo vệ, một tiến trình bị lỗi có thể **ăn cạn 100% RAM của máy chủ thật**, kéo theo hệ điều hành Windows/Linux bị đơ cứng và làm sập toàn bộ các dịch vụ khác trên máy.
* **Cơ chế bảo vệ của K8s:** Giám sát chặt chẽ mức tiêu thụ RAM của container. Khi phát hiện container vượt quá ngưỡng trần cho phép (**256MB**), Linux Kernel và K8s sẽ ngay lập tức kích hoạt "vũ khí tối thượng" **`OOMKilled`** để **tiêu diệt ngay lập tức container đó** và khởi động lại container mới tinh, bảo vệ an toàn tuyệt đối cho máy chủ!

---

## ⚙️ 2. Cấu hình Resource Limits đã thiết lập trong mã nguồn
Trong file [k8s/manifests/base/backend.yaml](file:///c:/Users/s3cr3t/Desktop/phần%20mềm%20devops/k8s/manifests/base/backend.yaml):
```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"    # Mức sàn tối thiểu được cấp
  limits:
    cpu: "500m"
    memory: "256Mi"    # ◄── MỨC TRẦN TỐI ĐA (Vòng kim cô 256MB)
```

---

## 🚀 3. Các bước thực hiện thử nghiệm chi tiết

### 🔹 Bước 1: Xem danh sách Pods Backend hiện tại
Mở PowerShell, chạy lệnh:
```powershell
kubectl get pods -l app=backend
```
**Kết quả mẫu:**
```text
NAME                      READY   STATUS    RESTARTS   AGE
backend-cbd46cf74-8hgc5   1/1     Running   0          1m
backend-cbd46cf74-f4gzf   1/1     Running   0          1m
```
> 👉 *Để ý cột **`RESTARTS`** của cả 2 Pods đang là **`0`**.*

---

### 🔹 Bước 2: Bơm dữ liệu gây rò rỉ RAM (Giả lập Memory Leak > 300MB)
Chọn tên 1 trong 2 Pod (ví dụ: `backend-cbd46cf74-8hgc5`), chạy lệnh sau để kích hoạt endpoint ngốn RAM:
```powershell
kubectl exec backend-cbd46cf74-8hgc5 -- wget -qO- --post-data="" http://127.0.0.1:5000/api/simulate-leak
```
> *(Code Backend sẽ ngay lập tức cấp phát 30 mảng Buffer, mỗi mảng 10MB = **Tổng cộng 300MB RAM**, vượt qua trần 256MB quy định của K8s!)*

Lệnh có thể sẽ báo ngắt kết nối do Pod bị tiêu diệt ngay lập tức giữa chừng:
`wget: error getting response: Connection reset by peer` hoặc kết thúc với mã lỗi.

---

### 🔹 Bước 3: Quan sát K8s kích hoạt án tử `OOMKilled`
Ngay lập tức kiểm tra lại danh sách Pod:
```powershell
kubectl get pods -l app=backend
```

👀 **Hiện tượng thực tế bạn sẽ thấy:**
1. Cột **`STATUS`** của Pod đó sẽ hiện chữ: **`OOMKilled`** hoặc chuyển sang khởi động lại!
2. Cột **`RESTARTS`** sẽ nhảy từ **`0` lên `1`**!
```text
NAME                      READY   STATUS    RESTARTS      AGE
backend-cbd46cf74-8hgc5   1/1     Running   1 (10s ago)   2m
backend-cbd46cf74-f4gzf   1/1     Running   0             2m
```

---

### 💡 Bước 4: Xem bằng chứng "bản án OOMKilled" của K8s
Để xem bằng chứng không thể chối cãi K8s đã "xử trảm" Pod vì tội ăn quá 256MB RAM:
Gõ lệnh:
```powershell
kubectl describe pod backend-cbd46cf74-8hgc5
```
Nhìn vào phần **`Last State`** của container:
* **`Reason: OOMKilled`**
* **`Exit Code: 137`** *(Mã lỗi tiêu chuẩn của Linux khi một tiến trình bị tiêu diệt do hết RAM!)*

👉 Nhờ có cơ chế này, máy tính của bạn hoàn toàn không bị giật lag hay treo đơ dù trong code có chứa lỗi rò rỉ RAM nghiêm trọng!
