# 🧪 KỊCH BẢN TEST: TÍNH NĂNG TỰ ĐỘNG DIỆT VÀ DỰNG LẠI POD KHI BỊ TREO (SELF-HEALING LIVENESS PROBE)

## 📌 1. Mục đích thử nghiệm
Kiểm chứng tính năng **Self-Healing (Tự chữa lành)** thông qua **Liveness Probe**:
* Trong thực tế, có những lỗi code khiến ứng dụng **không bị crash hẳn** mà rơi vào trạng thái **treo, deadlock hoặc đơ 100% CPU**, không thể trả lời người dùng.
* Khi gặp tình huống này, Kubernetes sẽ tự động phát hiện qua việc kiểm tra `/api/health` định kỳ thất bại, sau đó **tự động TIÊU DIỆT (KILL) container bị đơ và KHỞI ĐỘNG LẠI (RESTART)** mà không cần con người can thiệp.

---

## ⚙️ 2. Cơ chế đã cấu hình trong mã nguồn
Trong file `k8s/manifests/base/backend.yaml`:
```yaml
livenessProbe:
  httpGet:
    path: /api/health
    port: 5000
  initialDelaySeconds: 10
  periodSeconds: 10       # Cứ 10 giây K8s kiểm tra sức khỏe 1 lần
```
*(Nếu request này thất bại 3 lần liên tiếp, K8s kết luận Pod đã chết lâm sàng và thực hiện tiêu diệt ngay).*

---

## 🚀 3. Các bước thực hiện thử nghiệm

### 🔹 Bước 1: Xem danh sách Pods Backend hiện tại
Mở PowerShell, gõ lệnh:
```powershell
kubectl get pods -l app=backend
```
**Kết quả mẫu:**
```text
NAME                       READY   STATUS    RESTARTS   AGE
backend-6699f5f449-rcrxp   1/1     Running   0          2m
backend-6699f5f449-wb7sq   1/1     Running   0          2m
```
> 👉 *Hãy để ý cột **`RESTARTS`** hiện tại đang bằng **`0`**.*

---

### 🔹 Bước 2: Cố tình "đầu độc" làm treo 1 Pod (Giả lập Deadlock)
Chọn tên 1 trong 2 Pod (ví dụ: `backend-6699f5f449-wb7sq`), mở terminal và gửi tín hiệu ép Pod đó bị treo:
```powershell
kubectl exec <tên-pod> -- wget -qO- --post-data="" http://127.0.0.1:5000/api/simulate-crash
```
*Bạn sẽ nhận được thông báo phản hồi từ server:*
```json
{"message":"Server is now marked as DEAD/FROZEN! Liveness probe will fail."}
```
> Lúc này, Pod này đã bị đánh dấu "chết lâm sàng", mọi request kiểm tra `/api/health` sẽ bị trả về lỗi `500 Server is hung/deadlocked`.

---

### 🔹 Bước 3: Quan sát K8s tự động diệt và cứu sống Pod
Gõ lệnh theo dõi liên tục:
```powershell
kubectl get pods -l app=backend -w
```
*(Chờ khoảng 20 - 30 giây để Liveness probe thực hiện 3 lần kiểm tra thất bại).*

👀 **Hiện tượng thực tế bạn sẽ thấy:**
1. K8s phát hiện container không còn phản hồi `/api/health`.
2. K8s lập tức gửi tín hiệu `SIGKILL` để tắt container bị đơ.
3. K8s tự động khởi động lại container mới tinh.
4. Cột **`RESTARTS`** của Pod đó sẽ nhảy từ **`0` lên `1`**!
```text
NAME                       READY   STATUS    RESTARTS      AGE
backend-6699f5f449-wb7sq   1/1     Running   1 (5s ago)    3m
```
5. Pod trở lại trạng thái `READY 1/1` và khỏe mạnh bình thường!

---

### 💡 Bước 4: Xem bằng chứng "bản án" của K8s trong nhật ký sự kiện
Bạn có thể xem lý do K8s đã khai tử và hồi sinh Pod bằng lệnh:
```powershell
kubectl describe pod backend-6699f5f449-wb7sq
```
Kéo xuống phần **Events** ở dưới cùng, bạn sẽ thấy dòng nhật ký rõ ràng:
* ⚠️ `Warning Unhealthy: Liveness probe failed: HTTP probe failed with statuscode: 500`
* 🔄 `Normal Killing: Container backend failed liveness probe, will be restarted`
* 🚀 `Normal Created / Started: Created container backend`
