# 🏓 Pickleball Club Manager (PCM)

**Ứng dụng quản lý Câu lạc bộ Pickleball**

> Đồ án Mobile - Flutter + ASP.NET Core Web API

---

## 📋 Mục Lục

## 🌐 Live Demo & Deployment
- **Backend API (Swagger):** [https://pcm-bkt2.duckdns.org/swagger](https://pcm-bkt2.duckdns.org/swagger)
- **VPS IP:** `103.77.172.159`
- **APK Download:** `mobile/build/app/outputs/flutter-apk/app-release.apk`

1. [Yêu Cầu Hệ Thống](#-yêu-cầu-hệ-thống)
2. [Cài Đặt & Chạy Backend](#-cài-đặt--chạy-backend)
3. [Cài Đặt & Chạy Flutter](#-cài-đặt--chạy-flutter)
4. [Base URL API](#-base-url-api)
5. [Tài Khoản Test](#-tài-khoản-test)
6. [Build APK](#-build-apk)
7. [Cấu Trúc Dự Án](#-cấu-trúc-dự-án)

---

## 🔧 Yêu Cầu Hệ Thống

### Backend
- .NET 8 SDK
- SQL Server (LocalDB hoặc Express)

### Mobile
- Flutter SDK 3.19+
- Dart 3.0+
- Android Studio / VS Code
- Android Emulator hoặc thiết bị thật

---

## 🖥️ Cài Đặt & Chạy Backend

### Bước 1: Di chuyển vào thư mục backend
```bash
cd backend
```

### Bước 2: Restore dependencies
```bash
dotnet restore
```

### Bước 3: Tạo database và migration
```bash
dotnet ef database update
```

> **Lưu ý:** Nếu chưa có EF Tools, cài đặt bằng:
> ```bash
> dotnet tool install --global dotnet-ef
> ```

### Bước 4: Chạy Backend
```bash
dotnet run
```

**API sẽ chạy tại:**
- HTTP: `http://localhost:5000`
- HTTPS: `https://localhost:5001`

---

## 📱 Cài Đặt & Chạy Flutter

### Bước 1: Di chuyển vào thư mục mobile
```bash
cd mobile
```

### Bước 2: Cài đặt packages
```bash
flutter pub get
```

### Bước 3: Chạy ứng dụng

**Chạy trên Chrome (Web):**
```bash
flutter run -d chrome
```

**Chạy trên Android Emulator:**
```bash
flutter run -d emulator-5554
```

**Chạy trên thiết bị thật:**
```bash
flutter run
```

---

## 🌐 Base URL API

Cấu hình API URL tại file: `mobile/lib/core/constants.dart`

| Môi trường | Base URL |
|------------|----------|
| **Chrome/Web** | `http://localhost:5000/api` |
| **Android Emulator** | `http://10.0.2.2:5000/api` |
| **iOS Simulator** | `http://localhost:5000/api` |
| **Thiết bị thật (cùng WiFi)** | `http://<IP-máy-tính>:5000/api` |

### Cách lấy IP máy tính:

**Windows:**
```bash
ipconfig
```

**macOS/Linux:**
```bash
ifconfig | grep inet
```

---

## 👤 Tài Khoản Test (Mặc định)

| Vai trò | Email | Mật khẩu |
|---------|-------|----------|
| **Admin** | `admin@gmail.com` | `admin123` |
| **Thành viên** | `member1@pcm.local` | `Member@123` |

---

## 📦 Build APK

### Build APK Debug (nhanh):
```bash
cd mobile
flutter build apk --debug
```

### Build APK Release (tối ưu):
```bash
cd mobile
flutter build apk --release
```

**File APK sẽ được tạo tại:**
```
mobile/build/app/outputs/flutter-apk/app-release.apk
```

### Cài đặt APK lên thiết bị:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 📁 Cấu Trúc Dự Án

```
BKT2/
├── backend/                 # ASP.NET Core Web API
│   ├── Controllers/         # API Controllers
│   ├── Models/              # Entity Models
│   ├── Data/                # DbContext & Migrations
│   ├── Services/            # Business Logic
│   └── appsettings.json     # Config
│
└── mobile/                  # Flutter App
    ├── lib/
    │   ├── core/            # Constants, Theme
    │   ├── data/            # Models, Services
    │   └── ui/              # Screens, Widgets
    └── pubspec.yaml         # Dependencies
```

---

## ✨ Tính Năng Chính

### 👤 Người Dùng
- ✅ Đăng ký, Đăng nhập, Vân tay
- ✅ Xem hồ sơ, Hạng thành viên (VIP)
- ✅ Thông báo realtime

### 📅 Đặt Sân
- ✅ Xem lịch sân trống
- ✅ Đặt sân theo khung giờ
- ✅ Đặt sân định kỳ
- ✅ Hủy sân (hoàn tiền theo chính sách)

### 🏆 Giải Đấu
- ✅ Xem danh sách giải đấu
- ✅ Đăng ký tham gia
- ✅ Xem lịch thi đấu, kết quả
- ✅ Chat nhóm giải đấu

### 💰 Ví Điện Tử
- ✅ Nạp tiền (QR Code)
- ✅ Xem lịch sử giao dịch
- ✅ Thanh toán tự động

### 🔧 Admin
- ✅ Quản lý thành viên
- ✅ Duyệt nạp tiền
- ✅ Tạo giải đấu
- ✅ Báo cáo doanh thu

---

## 🚀 Quick Start

```bash
# Terminal 1 - Chạy Backend
cd backend
dotnet run

# Terminal 2 - Chạy Flutter
cd mobile
flutter pub get
flutter run -d chrome
```

---

**📧 Liên hệ:** Nếu có vấn đề, vui lòng tạo issue trên GitHub.

**🎉 Chúc giảng viên chấm bài vui vẻ!**
