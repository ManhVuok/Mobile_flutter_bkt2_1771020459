# 🚀 HƯỚNG DẪN DEPLOY PCM.Backend LÊN VPS (Phương pháp A1)

> **Lưu ý**: Project sử dụng .NET 10.0, do đó chúng ta sẽ:
> 1. Build (Publish) trên máy Windows
> 2. Upload file đã build lên VPS  
> 3. Cài .NET 10 Runtime trên VPS và chạy

---

## 📋 TỔNG QUAN

```
┌──────────────────┐       ┌──────────────────┐       ┌──────────────────┐
│   Máy Windows    │ ───▶  │   Upload VPS     │ ───▶  │   VPS chạy app   │
│   (dotnet pub)   │  SCP  │   (giải nén)     │       │   (dotnet run)   │
└──────────────────┘       └──────────────────┘       └──────────────────┘
```

---

## 🔧 BƯỚC 1: PUBLISH TRÊN MÁY WINDOWS (Làm trước khi có VPS)

Mở PowerShell tại thư mục backend:

```powershell
cd E:\Dowloat\MOBIE\BKT2\backend

# Publish ra thư mục
dotnet publish -c Release -o ./publish
```

Kết quả: Thư mục `publish/` chứa tất cả file cần thiết để chạy app.

**Nén thư mục publish:**
```powershell
# Nén thành file zip
Compress-Archive -Path .\publish\* -DestinationPath ..\pcm-backend.zip -Force
```

File `pcm-backend.zip` sẽ được tạo tại `E:\Dowloat\MOBIE\BKT2\`

---

## 🌐 BƯỚC 2: ĐĂNG KÝ DUCKDNS (Miễn phí - Làm trước khi có VPS)

1. Truy cập: https://www.duckdns.org/
2. Đăng nhập bằng GitHub/Google
3. Tạo subdomain, ví dụ: `pcm-bkt2` → Bạn sẽ có domain: `pcm-bkt2.duckdns.org`
4. Sau khi có VPS, nhập IP VPS vào ô "current ip" và nhấn "update ip"

---

## 🖥️ BƯỚC 3: CÀI ĐẶT TRÊN VPS

### 3.1 SSH vào VPS
```bash
ssh root@IP_VPS
# Nhập password
```

### 3.2 Cập nhật hệ thống
```bash
sudo apt update && sudo apt upgrade -y
```

### 3.3 Cài đặt .NET 10.0 Runtime

Vì .NET 10 mới ra, có thể cần cài manual:

```bash
# Tải .NET 10 SDK
wget https://dot.net/v1/dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --channel 10.0

# Thêm vào PATH
echo 'export DOTNET_ROOT=$HOME/.dotnet' >> ~/.bashrc
echo 'export PATH=$PATH:$HOME/.dotnet' >> ~/.bashrc
source ~/.bashrc

# Kiểm tra
dotnet --version
```

---

## 📤 BƯỚC 4: UPLOAD VÀ CHẠY APP

### 4.1 Upload file zip lên VPS

**Trên Windows (PowerShell):**
```powershell
scp E:\Dowloat\MOBIE\BKT2\pcm-backend.zip root@IP_VPS:/root/
```

**Trên VPS:**
```bash
# Tạo thư mục
mkdir -p /var/www/pcm-api

# Cài unzip
apt install unzip -y

# Giải nén
unzip /root/pcm-backend.zip -d /var/www/pcm-api

# Cấp quyền
chmod +x /var/www/pcm-api/PCM.Backend
```

### 4.2 Tạo file database trống (nếu chưa có)
```bash
touch /var/www/pcm-api/app.db
```

### 4.3 Test chạy thử
```bash
cd /var/www/pcm-api
dotnet PCM.Backend.dll --urls "http://0.0.0.0:5000"
```

Nếu thấy log "Now listening on: http://0.0.0.0:5000" → Thành công! 

Nhấn `Ctrl+C` để dừng.

---

## ⚙️ BƯỚC 5: TẠO SYSTEMD SERVICE

Để app chạy nền và tự khởi động khi VPS restart:

```bash
sudo nano /etc/systemd/system/pcm-api.service
```

Nội dung:
```ini
[Unit]
Description=PCM Backend API
After=network.target

[Service]
WorkingDirectory=/var/www/pcm-api
ExecStart=/root/.dotnet/dotnet /var/www/pcm-api/PCM.Backend.dll --urls "http://0.0.0.0:5000"
Restart=always
RestartSec=10
SyslogIdentifier=pcm-api
User=root
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_ROOT=/root/.dotnet

[Install]
WantedBy=multi-user.target
```

Lưu file (`Ctrl+O`, Enter, `Ctrl+X`)

Kích hoạt service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable pcm-api.service
sudo systemctl start pcm-api.service
sudo systemctl status pcm-api.service
```

---

## 🌐 BƯỚC 6: CÀI NGINX (REVERSE PROXY)

```bash
sudo apt install -y nginx
```

Cấu hình:
```bash
sudo nano /etc/nginx/sites-available/default
```

Thay nội dung bằng:
```nginx
server {
    listen 80;
    server_name pcm-bkt2.duckdns.org;  # Thay bằng domain của bạn

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Reload Nginx:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🔒 BƯỚC 7: CÀI SSL (TÙY CHỌN)

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d pcm-bkt2.duckdns.org
```

---

## ✅ BƯỚC 8: KIỂM TRA

Truy cập trình duyệt:
- Không có SSL: `http://pcm-bkt2.duckdns.org/swagger`
- Có SSL: `https://pcm-bkt2.duckdns.org/swagger`

Nếu thấy Swagger UI → Backend đã hoạt động! 🎉

---

## 📱 BƯỚC 9: CẬP NHẬT FLUTTER APP

Sửa file `mobile/lib/core/constants.dart`:

```dart
if (kReleaseMode) {
  return 'http://pcm-bkt2.duckdns.org';  // Domain của bạn
  // Hoặc: return 'https://pcm-bkt2.duckdns.org'; (nếu có SSL)
}
```

Build lại APK:
```powershell
cd E:\Dowloat\MOBIE\BKT2\mobile
flutter build apk --release
```

File APK mới: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🆘 XỬ LÝ LỖI

### Xem logs của app
```bash
sudo journalctl -u pcm-api.service -f
```

### Restart app
```bash
sudo systemctl restart pcm-api.service
```

### Xem trạng thái
```bash
sudo systemctl status pcm-api.service
```

### Mở firewall port 5000 và 80
```bash
sudo ufw allow 80
sudo ufw allow 5000
sudo ufw enable
```

---

## 📞 CHECKLIST TRƯỚC KHI NỘP BÀI

- [ ] VPS đang chạy
- [ ] Backend API hoạt động (test Swagger)
- [ ] Domain DuckDNS trỏ đúng IP
- [ ] Đã sửa URL trong Flutter constants.dart
- [ ] Đã build APK mới
- [ ] Test APK trên điện thoại thật (kết nối WiFi/4G khác)
- [ ] Nộp APK cho thầy
