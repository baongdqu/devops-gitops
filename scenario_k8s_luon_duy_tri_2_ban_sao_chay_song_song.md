# 🧪 KỊCH BẢN TEST: TÍNH NĂNG LUÔN DUY TRÌ 2 BẢN SAO CHẠY SONG SONG TRÊN K8S

## 📌 1. Mục đích thử nghiệm
Kiểm chứng cơ chế **Replication Controller & Self-Healing** của Kubernetes: Đảm bảo khi một Pod gặp sự cố, bị crash hoặc bị xóa bất ngờ, K8s sẽ ngay lập tức tự động khởi tạo Pod mới để duy trì đủ **2 bản sao (replicas: 2)** hoạt động liên tục.

---

## 🚀 2. Các bước thực hiện chi tiết

### 🔹 Bước 1: Kiểm tra 2 Pods Backend hiện tại
Mở PowerShell hoặc Command Prompt, chạy lệnh:
```powershell
kubectl get pods -l app=backend
```

**Kết quả mẫu:**
```text
NAME                      READY   STATUS    RESTARTS   AGE
backend-cd4f4b677-gqn28   1/1     Running   0          60s
backend-cd4f4b677-xpdsq   1/1     Running   0          60s
```
> *(Bạn sẽ thấy chính xác 2 Pods Backend đang ở trạng thái `Running` và `READY 1/1`)*.

---

### 🔹 Bước 2: Cố tình "xóa sổ" 1 Pod (Giả lập sự cố Pod bị sập)
Lấy tên của 1 trong 2 Pod ở Bước 1 (ví dụ: `backend-cd4f4b677-gqn28`) và chạy lệnh xóa:
```powershell
kubectl delete pod backend-cd4f4b677-gqn28
```

---

### 🔹 Bước 3: Quan sát K8s tự động "Hồi sinh" Pod mới
Ngay sau khi xóa, kiểm tra lại danh sách Pod:
```powershell
kubectl get pods -l app=backend
```

**Kết quả thực tế diễn ra:**
1. Pod cũ `backend-cd4f4b677-gqn28` chuyển sang trạng thái `Terminating` (đang tắt).
2. Bộ điều khiển **K8s Deployment Controller** phát hiện số lượng Pod chỉ còn `1 < 2` (vi phạm cấu hình `replicas: 2`).
3. Trong vòng **chưa đầy 1 giây**, K8s tự động tạo ngay một **Pod mới** với mã định danh ngẫu nhiên mới (ví dụ: `backend-cd4f4b677-abc12`) để đưa tổng số Pod trở về đúng **2 bản sao**.

---

## ⚡ 3. Mẹo xem trực tiếp theo thời gian thực (Live Stream Watch)
Để nhìn thấy K8s tự động xóa và tạo mới Pod nhảy dòng trực tiếp trên màn hình, bạn mở 2 cửa sổ terminal:

* **Cửa sổ 1 (Theo dõi liên tục):**
  ```powershell
  kubectl get pods -l app=backend -w
  ```
* **Cửa sổ 2 (Thực hiện xóa pod):**
  ```powershell
  kubectl delete pod <tên-pod>
  ```
👉 Bạn sẽ thấy ở Cửa sổ 1, Pod mới mọc lên thay thế ngay tức thì trước mắt bạn!
