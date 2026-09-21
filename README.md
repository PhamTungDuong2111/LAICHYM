# LAICHYM - iOS Screen Recorder & Livestream App

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2016.0%2B-blue.svg" alt="Platform iOS 16.0+">
  <img src="https://img.shields.io/badge/Language-Swift%205.9%2B-orange.svg" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/Framework-SwiftUI%20%7C%20ReplayKit-red.svg" alt="Frameworks">
  <img src="https://img.shields.io/badge/Architecture-Clean%20MVVM%20%2B%20Services-green.svg" alt="Architecture">
</p>

Ứng dụng **LAICHYM** là giải pháp ghi màn hình toàn hệ thống và phát sóng trực tiếp (Livestream) chuyên nghiệp dành riêng cho hệ điều hành iOS (iPhone & iPad), được phát triển theo mô hình ứng dụng mẫu **Screen Recorder Z - Livestream** (EVOLLY.APP trên App Store).

---

## 🌟 Tính Năng Chính (100% MIỄN PHÍ - KHÔNG MẤT TIỀN)

> [!NOTE]
> Ứng dụng đã được cấu hình **100% Miễn phí trọn đời**. Mọi tính năng cao cấp nhất như độ phân giải 1080p, 60 FPS, tắt Watermark logo, Livestream không giới hạn thời lượng đều được mở khóa sẵn mà không yêu cầu thanh toán bất kỳ chi phí nào!

1. **Ghi màn hình 1 chạm (Screen Recording):**
   - Hỗ trợ cả **Ghi màn hình trực tiếp trong ứng dụng** (sử dụng `RPScreenRecorder.startCapture` + `AVAssetWriter`) lưu trực tiếp ra file MP4 chuẩn không cần App Groups.
   - Hỗ trợ **Ghi màn hình toàn hệ thống** (Game, App khác) thông qua `ReplayKit Broadcast Extension`.
   - Thu đồng thời âm thanh hệ thống và micro bình luận tiếng nói.
   - Độ phân giải sắc nét 1080p 60 FPS Full HD.

2. **Livestream đa nền tảng (RTMP/RTMPS):**
   - **Camera Live:** Phát trực tiếp hình ảnh Camera + Micro lên **YouTube Live**, **Facebook Live**, **Twitch**, hoặc **Custom RTMP** kèm màn hình xem trước và đồng hồ giám sát thời lượng / bitrate thực tế.
   - **Screen Live:** Phát sóng trực tiếp toàn bộ màn hình khi chơi game.
   - Tích hợp công cụ **Kiểm tra kết nối RTMP** trước khi phát sóng để đảm bảo đường truyền ổn định.

3. **Face-Cam & Reaction Studio:**
   - Cửa sổ camera selfie nổi Picture-in-Picture (PiP), có thể kéo thả di chuyển tự do trên màn hình.
   - Chế độ **Reaction**: Vừa xem lại video vừa quay lại biểu cảm và giọng nói, sau đó tự động ghép thành video reaction hoàn chỉnh.

4. **Trình biên tập video tích hợp (Video Editor):**
   - **Trim:** Cắt tỉa thời lượng chính xác từng khung hình.
   - **Crop:** Cắt theo tỉ lệ chuẩn: 9:16 (TikTok / Reels / Shorts), 16:9 (YouTube), 1:1 (Instagram).
   - **Voiceover:** Thu âm lồng tiếng bổ sung vào video đã quay.
   - **Watermark:** Tự do bật hoặc tắt Watermark logo LAICHYM hoàn toàn miễn phí.

5. **Thư viện & Quản lý video (My Recordings):**
   - Lưu video trực tiếp vào Cuộn camera (**Photos / Camera Roll**) bằng `PHPhotoLibrary`.
   - Chia sẻ nhanh qua AirDrop, Tin nhắn, Mạng xã hội (`UIActivityViewController`).

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

### ⚠️ Hướng Dẫn Sử Dụng & Kiểm Tra Tính Năng:
1. **Phát trực tiếp Camera (Camera Live Stream):**
   - Mở app > chọn **Phát trực tiếp** > chọn tab **Camera**.
   - Hình ảnh từ camera trước/sau sẽ hiển thị xem trước trực tiếp.
   - Chọn nền tảng (YouTube / Facebook / Twitch) hoặc Custom RTMP, điền **Khóa luồng (Stream Key)**.
   - Bấm **BẮT ĐẦU PHÁT TRỰC TIẾP**. Tính năng này chạy trực tiếp qua RTMP Socket, hoạt động ngay cả với tài khoản Apple ID cá nhân miễn phí!
2. **Ghi hình trực tiếp 1-chạm (Direct In-App Recording):**
   - Tại trang chủ, bấm vào nút tròn đỏ **GHI HÌNH**.
   - Ứng dụng ghi hình trực tiếp và tự động xuất ra file MP4 lưu vào Thư viện LAICHYM.
3. **Quay màn hình toàn hệ thống (System Broadcast - Game/App khác):**
   - **Lưu ý của Apple:** Apple **không hỗ trợ** tính năng quay màn hình ReplayKit Broadcast trên iOS Simulator (máy ảo). Bạn cần cắm **iPhone/iPad thật** để thử tính năng quay ra ngoài app hoặc game.
   - Tại trang chủ, bấm vào nút Broadcast bên cạnh dòng chữ *"Quay toàn hệ thống"* hoặc mở **Trung tâm điều khiển (Control Center)** > Nhấn giữ biểu tượng Ghi màn hình > Chọn **LAICHYM** > Bắt đầu truyền phát.

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
