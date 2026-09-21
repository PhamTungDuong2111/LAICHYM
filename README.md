# LAICHYM - iOS Screen Recorder & Livestream App

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2016.0%2B-blue.svg" alt="Platform iOS 16.0+">
  <img src="https://img.shields.io/badge/Language-Swift%205.9%2B-orange.svg" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/Framework-SwiftUI%20%7C%20ReplayKit-red.svg" alt="Frameworks">
  <img src="https://img.shields.io/badge/Architecture-Clean%20MVVM%20%2B%20Services-green.svg" alt="Architecture">
</p>

Ứng dụng **LAICHYM** là giải pháp ghi màn hình toàn hệ thống và phát sóng trực tiếp (Livestream) chuyên nghiệp dành riêng cho hệ điều hành iOS (iPhone & iPad), được phát triển theo mô hình ứng dụng mẫu **Screen Recorder Z - Livestream** (EVOLLY.APP trên App Store).

---

## 🌟 Tính Năng Chính

1. **Ghi màn hình 1 chạm (System-Wide Screen Recording):**
   - Tích hợp `ReplayKit` & `RPSystemBroadcastPickerView`.
   - Thu đồng thời âm thanh hệ thống (Game/App) và micro bình luận.
   - Hỗ trợ độ phân giải lên đến 1080p 60 FPS (Full HD).
2. **Livestream đa nền tảng (RTMP/RTMPS):**
   - Hỗ trợ phát trực tiếp lên **YouTube Live**, **Facebook Live**, **Twitch**, hoặc bất kỳ **Custom RTMP Server** nào (TikTok Live Studio, Shopee Live, v.v.).
   - Kiểm tra kết nối TCP socket cổng 1935 và giám sát thông số trực tiếp (Bitrate, FPS, Rớt khung hình, Thời lượng).
3. **Face-Cam & Reaction Studio:**
   - Cửa sổ camera selfie Picture-in-Picture (PiP) nổi, có thể kéo thả di chuyển tự do trên màn hình.
   - Tùy chỉnh hình dạng: Tròn, Bo góc, Vuông, Bầu dục.
   - Chế độ **Reaction**: Xem lại video đã quay trong khi camera trước ghi lại phản ứng và giọng nói của bạn, sau đó tự động ghép thành một video hoàn chỉnh.
4. **Trình biên tập video tích hợp (Video Editor):**
   - **Trim:** Cắt tỉa thời lượng chính xác từng khung hình.
   - **Crop:** Cắt theo tỉ lệ khung hình chuẩn: 9:16 (TikTok / Reels / Shorts), 16:9 (YouTube), 1:1 (Instagram).
   - **Voiceover:** Thu âm lồng tiếng bổ sung vào video đã quay kèm bộ trộn âm lượng (Audio Mixer).
   - **Watermark:** Tùy chọn gắn hoặc gỡ bỏ logo bản quyền.
5. **Thư viện & Quản lý video (My Recordings):**
   - Trình phát video chuyên nghiệp hỗ trợ Picture-in-Picture.
   - Lưu video trực tiếp vào Cuộn camera (**Photos / Camera Roll**) bằng `PHPhotoLibrary`.
   - Chia sẻ nhanh qua AirDrop, Tin nhắn, Mạng xã hội (`UIActivityViewController`).
6. **Gói VIP Premium (StoreKit 2):**
   - Mở khóa 1080p 60fps, xóa watermark, stream không giới hạn.
   - Hỗ trợ gói Tuần, Tháng, Năm (với 3 ngày dùng thử miễn phí) và gói Trọn đời.

---

## 📁 Cấu Trúc Mã Nguồn

```
LAICHYM/
├── LAICHYM.xcodeproj/               # Xcode Project cấu hình đầy đủ 2 Targets
│   └── project.pbxproj
├── LAICHYM/                         # Target chính (Main iOS App - SwiftUI)
│   ├── App/
│   │   ├── LAICHYMApp.swift         # Điểm khởi đầu ứng dụng
│   │   └── ContentView.swift        # Main View với Custom Glassmorphic Tab Bar
│   ├── Models/
│   │   ├── RecordingItem.swift      # Model video đã ghi
│   │   ├── LivePlatform.swift       # Cấu hình YouTube, Facebook, Twitch, RTMP
│   │   ├── StreamSettings.swift     # Thông số video, bitrate, fps
│   │   ├── VideoEditConfig.swift    # Cấu hình cắt crop, lồng tiếng
│   │   └── UserSettings.swift       # Lưu cài đặt qua App Group UserDefaults
│   ├── Services/
│   │   ├── StorageManager.swift     # Quản lý lưu trữ trong App Group Container
│   │   ├── ReplayKitManager.swift   # Điều khiển ghi màn hình ReplayKit
│   │   ├── FaceCamService.swift     # AVCaptureSession camera selfie PiP
│   │   ├── VideoEditorService.swift # AVMutableComposition cắt, crop, mix audio
│   │   ├── RTMPStreamer.swift       # Quản lý socket RTMP
│   │   └── StoreKitManager.swift    # Thanh toán StoreKit 2 native
│   ├── Views/
│   │   ├── Home/HomeView.swift
│   │   ├── Livestream/LivestreamView.swift
│   │   ├── Reaction/ReactionStudioView.swift
│   │   ├── Editor/VideoEditorView.swift
│   │   ├── Library/RecordingsGalleryView.swift
│   │   ├── Settings/SettingsView.swift
│   │   ├── Premium/PaywallView.swift
│   │   └── Components/
│   │       ├── BroadcastPickerRepresentable.swift
│   │       ├── CameraPreviewRepresentable.swift
│   │       └── VideoPlayerRepresentable.swift
│   └── Resources/
│       ├── Info.plist
│       ├── LAICHYM.entitlements
│       └── Assets.xcassets/
├── LAICHYMBroadcast/                # Target phụ (iOS Broadcast Upload Extension)
│   ├── SampleHandler.swift          # Xử lý CMSampleBuffer từ màn hình hệ thống
│   ├── Info.plist
│   └── LAICHYMBroadcast.entitlements
└── simulator/                       # Bộ giả lập giao diện iPhone 16 Pro trên Web
    ├── package.json
    ├── server.js
    └── public/ (index.html, style.css, app.js)
```

---

## 🚀 Hướng Dẫn Chạy Dự Án Trên macOS & Xcode

### Bước 1: Clone kho mã nguồn về máy Mac
```bash
git clone https://github.com/PhamTungDuong2111/LAICHYM.git
cd LAICHYM
```

### Bước 2: Mở dự án trong Xcode
```bash
open LAICHYM.xcodeproj
```

### Bước 3: Cấu hình Signing & Capabilities
1. Trong thanh điều hướng bên trái của Xcode, nhấp vào biểu tượng **dự án LAICHYM**.
2. Chọn target **`LAICHYM`**:
   - Chuyển sang tab **Signing & Capabilities**.
   - Tại mục **Team**, chọn tài khoản Apple Developer của bạn.
   - Tại mục **App Groups**, đảm bảo đã chọn nhóm `group.com.laichym.app` (hoặc đổi theo Bundle ID riêng của bạn).
3. Chọn target **`LAICHYMBroadcast`**:
   - Chọn cùng **Team** và cùng **App Groups** như target chính.

### Bước 4: Build và Trải nghiệm
- Kết nối iPhone/iPad thật qua cáp hoặc chọn một thiết bị Simulator (ví dụ: iPhone 16 Pro - iOS 18).
- Nhấn tổ hợp phím **Cmd + R** để biên dịch và khởi chạy ứng dụng.

---

## 💻 Trình Giả Lập Web Cục Bộ (Tùy chọn)

Nếu bạn muốn chạy thử nhanh giao diện trên trình duyệt:
```bash
cd simulator
node server.js
```
Truy cập: `http://localhost:3000`

---

## 📄 Bản Quyền & Giấy Phép

Dự án phát triển cho mục đích học tập, ứng dụng thực tế và triển khai sản phẩm thương mại trên iOS App Store.
Mọi thắc mắc và đóng góp vui lòng liên hệ tác giả.
