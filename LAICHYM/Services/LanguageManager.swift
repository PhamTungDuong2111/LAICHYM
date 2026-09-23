import Foundation
import Combine

// MARK: - Supported Application Languages
public enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case vietnamese = "vi"
    case english = "en"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .vietnamese: return "Tiếng Việt"
        case .english: return "English"
        }
    }
    
    public var flag: String {
        switch self {
        case .vietnamese: return "🇻🇳"
        case .english: return "🇺🇸"
        }
    }
}

// MARK: - Centralized Localization Manager
public class LanguageManager: ObservableObject {
    public static let shared = LanguageManager()
    
    private let languageKey = "selectedAppLanguage"
    private let defaults: UserDefaults
    
    @Published public var currentLanguage: AppLanguage {
        didSet {
            defaults.set(currentLanguage.rawValue, forKey: languageKey)
            defaults.synchronize()
        }
    }
    
    public init() {
        self.defaults = UserDefaults(suiteName: "group.com.laichym.app") ?? UserDefaults.standard
        if let saved = defaults.string(forKey: languageKey), let lang = AppLanguage(rawValue: saved) {
            self.currentLanguage = lang
        } else {
            // Mặc định Tiếng Việt
            self.currentLanguage = .vietnamese
        }
    }
    
    public func setLanguage(_ lang: AppLanguage) {
        if self.currentLanguage != lang {
            self.currentLanguage = lang
        }
    }
    
    // MARK: - Localized String Translation Helper
    public func s(_ key: String) -> String {
        let isEn = currentLanguage == .english
        
        switch key {
        // MARK: Common
        case "ok": return isEn ? "OK" : "Đồng ý"
        case "done": return isEn ? "Done" : "Xong"
        case "close": return isEn ? "Close" : "Đóng"
        case "cancel": return isEn ? "Cancel" : "Hủy"
        case "save": return isEn ? "Save" : "Lưu"
        case "delete": return isEn ? "Delete" : "Xóa"
        case "share": return isEn ? "Share" : "Chia sẻ"
        case "rename": return isEn ? "Rename" : "Đổi tên"
        case "understood": return isEn ? "Understood" : "Đã hiểu"
        case "notice": return isEn ? "Notice" : "Thông báo"
        case "free": return isEn ? "FREE" : "MIỄN PHÍ"
        case "success": return isEn ? "Success" : "Thành công"
        case "great": return isEn ? "Great" : "Tuyệt vời"
        case "seconds": return isEn ? "seconds" : "giây"
        case "off": return isEn ? "Off" : "Tắt"
            
        // MARK: Tab Bar
        case "tab_home": return isEn ? "Home" : "Trang chủ"
        case "tab_live": return isEn ? "Live" : "Trực tiếp"
        case "tab_library": return isEn ? "Library" : "Thư viện"
        case "tab_settings": return isEn ? "Settings" : "Cài đặt"
            
        // MARK: Home View
        case "home_tagline": return isEn ? "Screen Recorder & Live" : "Screen Recorder & Live"
        case "home_free_banner_title": return isEn ? "All premium features unlocked 100% Free" : "Ứng dụng mở khóa toàn bộ tính năng Miễn phí"
        case "home_free_banner_sub": return isEn ? "Record 1080p 60fps, no watermark, unlimited live" : "Quay 1080p 60fps, xóa logo, livestream không giới hạn hoàn toàn miễn phí"
        case "status_recording": return isEn ? "RECORDING" : "ĐANG GHI HÌNH"
        case "status_ready": return isEn ? "READY" : "SẴN SÀNG"
        case "btn_record": return isEn ? "RECORD" : "GHI HÌNH"
        case "btn_stop": return isEn ? "STOP" : "DỪNG"
        case "system_broadcast_label": return isEn ? "System Broadcast (Game/Apps):" : "Quay toàn hệ thống (Game/App khác):"
        case "toggle_mic": return isEn ? "Microphone" : "Microphone"
        case "toggle_audio": return isEn ? "Device Audio" : "Âm thanh máy"
        case "toggle_facecam": return isEn ? "Face-Cam" : "Face-Cam"
        case "tool_livestream": return isEn ? "Livestream" : "Phát trực tiếp"
        case "tool_livestream_sub": return isEn ? "YouTube, Facebook, Twitch" : "YouTube, Facebook, Twitch"
        case "tool_reaction": return isEn ? "Reaction Studio" : "Reaction Studio"
        case "tool_reaction_sub": return isEn ? "Webcam & Commentary" : "Lồng webcam & bình luận"
        case "tool_editor": return isEn ? "Video Editor" : "Chỉnh sửa Video"
        case "tool_editor_sub": return isEn ? "Trim, crop, voiceover" : "Cắt, crop, lồng tiếng"
        case "tool_guide": return isEn ? "Setup Guide" : "Hướng dẫn cài đặt"
        case "tool_guide_sub": return isEn ? "Enable Control Center" : "Bật Trung tâm điều khiển"
        case "recent_recordings": return isEn ? "Recent Recordings" : "Video gần đây"
        case "no_recent_videos": return isEn ? "No recordings yet" : "Chưa có video quay màn hình nào"
        case "no_recent_videos_hint": return isEn ? "Tap the red record button above to start your first capture" : "Nhấn nút Ghi hình ở trên để bắt đầu quay clip đầu tiên của bạn"
        case "record_finished_alert": return isEn ? "Screen recording finished! Video saved to LAICHYM Library." : "Ghi màn hình hoàn tất! Video đã được lưu vào Thư viện LAICHYM."
            
        // MARK: Livestream View
        case "live_title": return isEn ? "Livestream (100% Free)" : "Phát trực tiếp (100% Free)"
        case "live_source_camera": return isEn ? "Live Camera" : "Camera Trực Tiếp"
        case "live_source_screen": return isEn ? "Screen Record" : "Ghi Màn Hình"
        case "live_camera_preview": return isEn ? "Camera Preview" : "Xem trước Camera"
        case "live_stream_key_help": return isEn ? "How to get Stream Key" : "Hướng dẫn lấy Khóa luồng"
        case "live_server_info": return isEn ? "RTMP Server Information" : "Thông tin máy chủ RTMP"
        case "live_server_url": return isEn ? "Server URL (rtmp://...)" : "URL máy chủ (Server URL)"
        case "live_stream_key": return isEn ? "Stream Key" : "Khóa luồng (Stream Key)"
        case "live_enter_stream_key": return isEn ? "Enter Stream Key" : "Nhập Stream Key"
        case "live_paste_clipboard": return isEn ? "Paste from clipboard" : "Dán từ bộ nhớ tạm"
        case "live_test_connection": return isEn ? "Test RTMP Connection" : "Kiểm tra kết nối RTMP"
        case "live_testing": return isEn ? "Testing connection..." : "Đang kiểm tra kết nối..."
        case "live_quality_settings": return isEn ? "Stream Quality Settings" : "Cấu hình chất lượng phát"
        case "live_resolution": return isEn ? "Resolution" : "Độ phân giải"
        case "live_fps": return isEn ? "Frame Rate (FPS)" : "Tốc độ khung hình (FPS)"
        case "live_bitrate": return isEn ? "Transmission Bitrate" : "Bitrate truyền tải"
        case "live_start_btn": return isEn ? "START LIVESTREAM" : "BẮT ĐẦU PHÁT TRỰC TIẾP"
        case "live_stop_btn": return isEn ? "STOP LIVESTREAM" : "DỪNG PHÁT TRỰC TIẾP"
        case "live_screen_broadcast_title": return isEn ? "Broadcast Entire Screen:" : "Phát màn hình toàn hệ thống:"
        case "live_screen_broadcast_hint": return isEn ? "Tap the button beside to start broadcasting via ReplayKit" : "Bấm vào nút bên cạnh để bắt đầu phát sóng màn hình qua ReplayKit"
        case "live_status_active": return isEn ? "LIVE STREAMING" : "ĐANG PHÁT TRỰC TIẾP"
            
        // MARK: Reaction Studio
        case "reaction_title": return isEn ? "Reaction Studio" : "Reaction Studio"
        case "reaction_select_prompt": return isEn ? "Select a video to react to" : "Chọn video để thực hiện Reaction"
        case "reaction_select_hint": return isEn ? "Overlay your facecam and record audio commentary while the video plays" : "Lồng camera khuôn mặt và ghi âm lời bình luận trực tiếp trong khi video đang phát"
        case "reaction_empty_library": return isEn ? "No videos found in your library." : "Bạn chưa có video nào trong thư viện."
        case "reaction_start": return isEn ? "START REACTION" : "BẮT ĐẦU REACTION"
        case "reaction_stop": return isEn ? "STOP REACTION" : "DỪNG QUAY REACTION"
            
        // MARK: Video Editor
        case "editor_title": return isEn ? "Video Editor" : "Chỉnh sửa Video"
        case "editor_select_prompt": return isEn ? "Select a video to edit" : "Chọn video cần chỉnh sửa"
        case "editor_trim_title": return isEn ? "Trim Duration" : "Cắt thời lượng (Trim)"
        case "editor_start": return isEn ? "Start:" : "Bắt đầu:"
        case "editor_end": return isEn ? "End:" : "Kết thúc:"
        case "editor_crop_title": return isEn ? "Aspect Ratio (Crop)" : "Tỉ lệ khung hình (Crop)"
        case "editor_mixer_title": return isEn ? "Audio Mixer" : "Bộ trộn âm thanh (Audio Mixer)"
        case "editor_original_audio": return isEn ? "Original Audio:" : "Âm thanh gốc:"
        case "editor_voiceover_audio": return isEn ? "Voiceover Audio:" : "Âm thanh lồng tiếng:"
        case "editor_watermark_title": return isEn ? "LAICHYM Watermark Logo" : "Logo bản quyền LAICHYM"
        case "editor_watermark_sub": return isEn ? "Toggle watermark on/off 100% free" : "Tùy chọn Bật/Tắt logo hoàn toàn miễn phí"
        case "editor_export_btn": return isEn ? "EXPORT VIDEO (MP4)" : "XUẤT VIDEO (MP4)"
        case "editor_exporting": return isEn ? "Exporting video:" : "Đang xuất video:"
        case "editor_export_success_title": return isEn ? "Video Exported Successfully!" : "Xuất video thành công!"
        case "editor_export_success_msg": return isEn ? "The edited video has been saved to your LAICHYM Library." : "Video đã chỉnh sửa được lưu vào Thư viện video LAICHYM của bạn."
            
        // MARK: Gallery / Library
        case "lib_title": return isEn ? "Video Library" : "Thư viện video"
        case "lib_search_placeholder": return isEn ? "Search videos..." : "Tìm kiếm video..."
        case "lib_empty_title": return isEn ? "No videos found" : "Không có video nào"
        case "lib_empty_desc": return isEn ? "Screen recordings and live streams will appear here" : "Các video quay màn hình hoặc livestream sẽ xuất hiện tại đây"
        case "lib_detail_title": return isEn ? "Video Details" : "Chi tiết video"
        case "lib_save_photos": return isEn ? "Save to Photos (Camera Roll)" : "Lưu vào Ảnh (Camera Roll)"
        case "lib_save_success": return isEn ? "Video saved to Photos Album" : "Video đã được lưu vào Album Ảnh"
            
        // MARK: Settings View
        case "settings_title": return isEn ? "Settings" : "Cài đặt"
        case "settings_language": return isEn ? "Language / Ngôn ngữ" : "Ngôn ngữ / Language"
        case "settings_language_desc": return isEn ? "Choose your preferred display language" : "Chọn ngôn ngữ hiển thị trong ứng dụng"
        case "settings_control_center_title": return isEn ? "How to enable Screen Recording on iOS" : "Cách bật Ghi màn hình trên iOS"
        case "settings_cc_step_1": return isEn ? "Open Settings on your iPhone > select Control Center." : "Mở Cài đặt (Settings) trên iPhone > chọn Trung tâm điều khiển (Control Center)."
        case "settings_cc_step_2": return isEn ? "Find 'Screen Recording' and tap the green (+) icon to add it." : "Tìm mục 'Ghi màn hình' (Screen Recording) và bấm dấu (+) màu xanh để thêm vào."
        case "settings_cc_step_3": return isEn ? "Swipe down from the top right corner to open Control Center." : "Vuốt từ góc trên bên phải màn hình xuống để mở Trung tâm điều khiển."
        case "settings_cc_step_4": return isEn ? "Long press the Screen Recording button > choose 'LAICHYM' > Start Broadcast." : "Nhấn giữ (Long press) vào nút Ghi màn hình > chọn 'LAICHYM' > Bắt đầu truyền phát."
        case "settings_default_video": return isEn ? "Default Video Settings" : "Thông số video mặc định"
        case "settings_countdown": return isEn ? "Countdown before recording" : "Đếm ngược trước khi quay"
        case "settings_watermark": return isEn ? "Include LAICHYM Watermark" : "Chèn Watermark logo LAICHYM"
        case "settings_watermark_sub": return isEn ? "Disabled by default (100% free)" : "Mặc định Tắt (hoàn toàn miễn phí)"
        case "settings_audio_title": return isEn ? "Audio Configuration" : "Cấu hình âm thanh"
        case "settings_audio_mic": return isEn ? "Enable microphone for commentary" : "Bật micro ghi âm bình luận"
        case "settings_audio_sys": return isEn ? "Record system audio (Game/App)" : "Ghi âm thanh hệ thống (Game/App)"
        case "settings_app_info": return isEn ? "App Information" : "Thông tin ứng dụng"
        case "settings_version": return isEn ? "Version" : "Phiên bản"
        case "settings_privacy": return isEn ? "Privacy Policy" : "Chính sách bảo mật"
        case "settings_terms": return isEn ? "Terms of Service" : "Điều khoản dịch vụ"
            
        // MARK: Paywall / About View
        case "pw_title": return isEn ? "LAICHYM PRO" : "LAICHYM PRO"
        case "pw_subtitle": return isEn ? "All features completely unlocked for FREE" : "Ứng dụng mở khóa toàn bộ tính năng hoàn toàn MIỄN PHÍ"
        case "pw_feat1_title": return isEn ? "Record & Stream 1080p 60 FPS Full HD" : "Quay & Stream 1080p 60 FPS Full HD"
        case "pw_feat1_sub": return isEn ? "Highest quality completely free of charge" : "Chất lượng cao nhất hoàn toàn miễn phí"
        case "pw_feat2_title": return isEn ? "Toggle Watermark Logo Freely" : "Tùy chọn Bật/Tắt Logo bản quyền"
        case "pw_feat2_sub": return isEn ? "Export clean videos without forced branding" : "Xuất video sạch sẽ không bị gắn watermark bắt buộc"
        case "pw_feat3_title": return isEn ? "Livestream YouTube, Facebook, Twitch" : "Livestream YouTube, Facebook, Twitch"
        case "pw_feat3_sub": return isEn ? "Stream camera & screen without time limits" : "Phát sóng trực tiếp camera & màn hình không giới hạn"
        case "pw_feat4_title": return isEn ? "Full Video Editor Suite" : "Bộ công cụ Video Editor đầy đủ"
        case "pw_feat4_sub": return isEn ? "Trim clips, crop 9:16 for TikTok, record voiceover" : "Cắt ngắn, crop tỉ lệ 9:16 TikTok, lồng tiếng micro"
        case "pw_lifetime_badge": return isEn ? "Lifetime License (Free)" : "Gói bản quyền Vĩnh viễn (Miễn phí)"
        case "pw_lifetime_desc": return isEn ? "Zero charges, no subscription fees, no intrusive ads" : "Không thu bất kỳ khoản phí nào, không có quảng cáo phiền toái"
        case "pw_start_btn": return isEn ? "START USING NOW" : "BẮT ĐẦU SỬ DỤNG NGAY"
            
        default:
            return key
        }
    }
}
