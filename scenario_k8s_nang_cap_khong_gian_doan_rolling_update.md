# 🧪 KỊCH BẢN TEST: NÂNG CẤP PHẦN MỀM KHÔNG GIÁN ĐOẠN (KUBERNETES ROLLING UPDATE ZERO-DOWNTIME)

## 📌 1. Mục đích thử nghiệm
Kiểm chứng tính năng **Rolling Update (Cập nhật cuốn chiếu)** của Kubernetes Deployment:
* **Vấn đề thực tế:** Khi công ty tung ra tính năng mới (phiên bản `v2.0` / `v3.0`), nếu tắt máy chủ cũ rồi mới bật máy chủ mới, người dùng sẽ bị lỗi trắng trang hoặc ngắt kết nối (Downtime).
* **Cơ chế hoạt động của K8s:** 
  1. K8s giữ nguyên các Pods cũ đang phục vụ người dùng.
  2. Bật dần các Pods mới song song bên cạnh.
  3. K8s dùng `readinessProbe` kiểm tra Pod mới nạp xong 100% rồi mới cho nhận khách và ngắt dần các Pod cũ.
  4. Người dùng liên tục gọi API mà **không bị trượt hay rớt một request nào (Zero-Downtime)**!

---

## ⚙️ 2. Cấu hình Rolling Update trong Kubernetes
Mặc định trong Kubernetes Deployment (như `backend.yaml`), chiến lược cập nhật là:
```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25%        # Được phép bật thêm tối đa bao nhiêu Pods mới
      maxUnavailable: 25%  # Tối đa bao nhiêu Pods cũ được phép tắt cùng lúc
```

---

## 🚀 3. Các bước thực hiện thử nghiệm chi tiết (Trực quan hóa Zero-Downtime)

Thử nghiệm này cần **2 cửa sổ PowerShell** để bạn nhìn thấy: vừa bắn request liên tục, vừa nâng cấp phiên bản mà không bị rớt mạng:

---

### 🔹 Bước 1: Mở Cửa Sổ 1 – Bắn Request liên tục (Đóng vai Khách hàng đang dùng Web)
Mở cửa sổ PowerShell 1 và chạy lệnh gửi request liên tục mỗi 0.5 giây:

```powershell
while ($true) {
    try {
        $res = kubectl exec deployment/frontend -- wget -qO- http://backend-service:5000/api/health
        Write-Host "✅ [200 OK] Khach hang van goi duoc API - $res" -ForegroundColor Green
    } catch {
        Write-Host "❌ [LOI] Mat ket noi server!" -ForegroundColor Red
    }
    Start-Sleep -Milliseconds 500
}
```
👉 *Bạn sẽ thấy màn hình liên tục in ra các dòng chữ màu xanh lá cây `✅ [200 OK]` không ngừng nghỉ.*

---

### 🔹 Bước 2: Mở Cửa Sổ 2 – Tiến hành Cập nhật Phiên Bản Mới (DevOps nâng cấp)
Trong lúc Cửa sổ 1 vẫn đang chạy ầm ầm, bạn mở cửa sổ PowerShell thứ 2 và ra lệnh cho K8s nâng cấp Backend:

```powershell
kubectl rollout restart deployment/backend
```

Kiểm tra quá trình cuốn chiếu diễn ra bằng lệnh:
```powershell
kubectl rollout status deployment/backend
```
*Bạn sẽ thấy K8s báo cáo từng bước:*
```text
Waiting for deployment "backend" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "backend" rollout to finish: 2 out of 2 new replicas have been updated...
Waiting for deployment "backend" rollout to finish: 1 old replicas are pending termination...
deployment "backend" successfully rolled out
```

---

### 🔹 Bước 3: Quan sát điều kỳ diệu ở Cửa Sổ 1
Quay lại nhìn màn hình **Cửa sổ 1**:

👀 **Hiện tượng bạn sẽ chứng kiến:**
* Trong suốt quá trình cập nhật, dòng log xanh **`✅ [200 OK]`** vẫn chạy đều đặn, **KHÔNG CÓ BẤT KỲ DÒNG ĐỎ NÀO BỊ RỚT!**
* Bạn sẽ thấy tên của `pod` trong kết quả JSON tự động chuyển đổi mượt mà từ tên của Pod cũ sang tên của Pod mới!

---

### 💡 Bước 4: Xem lịch sử các đợt phát hành (Release History & Rollback)
Kubernetes lưu lại toàn bộ các đợt cập nhật như lịch sử `git`:
```powershell
kubectl rollout history deployment/backend
```
Nếu bản cập nhật mới có lỗi, bạn chỉ cần gõ lệnh **"Quay xe thần tốc"** trong 1 giây:
```powershell
kubectl rollout undo deployment/backend
```
👉 K8s sẽ ngay lập tức cuốn chiếu lùi về phiên bản trước đó mà website cũng không bị gián đoạn dù chỉ 1 giây!
