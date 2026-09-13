# 🧪 KỊCH BẢN TEST: TỰ ĐỘNG TĂNG LÊN 5 PODS KHI CPU > 70% (HORIZONTAL POD AUTOSCALER - HPA)

## 📌 1. Mục đích thử nghiệm
Kiểm chứng tính năng **Tự động co giãn theo tải thực tế (Auto-scaling)** của Kubernetes:
* Khi lượng người dùng truy cập tăng đột biến, CPU của các Pod Backend bị đẩy lên cao (vượt mức trung bình **70%**).
* **Kubernetes HPA (Horizontal Pod Autoscaler)** sẽ tự động phát hiện tình trạng quá tải và **nhân bản (Scale-out) từ 2 Pods lên 3, 4 và tối đa 5 Pods** để san sẻ gánh nặng, bảo vệ hệ thống không bị nghẽn mạng.
* Khi hết đợt cao điểm (CPU hạ nhiệt), K8s sẽ tự động thu hẹp (Scale-in) trở về mức ban đầu (**2 Pods**) để tiết kiệm chi phí server cho công ty.

---

## ⚙️ 2. Cấu hình HPA đã thiết lập trong mã nguồn
Trong file [k8s/manifests/base/ingress-hpa-config.yaml](file:///c:/Users/s3cr3t/Desktop/phần%20mềm%20devops/k8s/manifests/base/ingress-hpa-config.yaml):
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 2      # Mức sàn tối thiểu: 2 Pods
  maxReplicas: 5      # Mức trần tối đa: 5 Pods
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70  # Ngưỡng kích hoạt: CPU > 70%
```

---

## 🚀 3. Các bước thực hiện thử nghiệm chi tiết

### 🔹 Bước 1: Mở cửa sổ theo dõi HPA và số lượng Pods
Mở một cửa sổ PowerShell riêng (Cửa sổ 1) và chạy lệnh sau để theo dõi biến động theo thời gian thực:
```powershell
kubectl get hpa backend-hpa -w
```

**Trạng thái ban đầu:**
```text
NAME          REFERENCE            TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
backend-hpa   Deployment/backend   cpu: 1%/70%     2         5         2          10m
```
> *(Số bản sao hiện tại là `REPLICAS: 2`, CPU đang rất thấp ~1%).*

---

### 🔹 Bước 2: Bơm tải cực mạnh (Tạo bão Traffic giả lập CPU > 70%)
Mở một cửa sổ PowerShell thứ hai (Cửa sổ 2) và chạy một container phụ để bắn dồn dập hàng chục ngàn request vào Backend:

```powershell
kubectl run -i --tty load-generator --rm --image=busybox:1.36 --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://backend-service:5000/api/todos; done"
```
> *(Lệnh này sẽ tạo ra một vòng lặp vĩnh cửu gọi API liên tục không ngừng nghỉ để đẩy CPU của Backend lên trên 70%).*

---

### 🔹 Bước 3: Quan sát K8s tự động nhân bản Pods
Quay lại nhìn màn hình **Cửa sổ 1**, bạn sẽ thấy các chỉ số biến đổi ngoạn mục:

1. **CPU bắt đầu vọt lên:**
   ```text
   backend-hpa   Deployment/backend   cpu: 85%/70%    2   5   2
   ```
2. **K8s kích hoạt quy tắc Auto-scaling:**
   HPA phát hiện `85% > 70%`, nó lập tức ra lệnh cho Deployment tăng số Pod:
   ```text
   backend-hpa   Deployment/backend   cpu: 85%/70%    2   5   3   <-- Tăng lên 3 Pods
   backend-hpa   Deployment/backend   cpu: 90%/70%    2   5   4   <-- Tăng lên 4 Pods
   backend-hpa   Deployment/backend   cpu: 75%/70%    2   5   5   <-- Chạm trần tối đa 5 Pods!
   ```

3. Mở một tab terminal khác gõ `kubectl get pods -l app=backend`, bạn sẽ thấy **đúng 5 Pods Backend** đang cùng nhau gánh tải song song!

---

### 🔹 Bước 4: Dừng bão tải & Xem K8s tự động thu gọn về 2 Pods
1. Tại **Cửa sổ 2**, bạn bấm tổ hợp phím **`Ctrl + C`** để dừng vòng lặp bắn tải.
2. CPU sẽ lập tức tụt về `0% - 1%`.
3. Sau khoảng **3 đến 5 phút** (thời gian làm dịu - stabilization window của K8s để tránh tăng giảm đột ngột), K8s sẽ tự động xóa dần các Pod thừa và đưa hệ thống quay trở về đúng **2 Pods** ban đầu!

---

## 💡 Mẹo kiểm tra nhanh các Pod mới sinh ra:
```powershell
kubectl get pods -l app=backend
```
Bạn sẽ thấy 5 Pods với tuổi đời (AGE) chỉ vài giây/phút, chứng minh K8s vừa sinh ra chúng tức thì trong cơn bão tải!
