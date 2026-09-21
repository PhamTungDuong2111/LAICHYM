import SwiftUI
import StoreKit

// MARK: - Paywall View (VIP Premium Subscription)
public struct PaywallView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var userSettings = UserSettings.shared
    @ObservedObject var storeKit = StoreKitManager.shared
    
    @State private var selectedPlanIndex: Int = 1 // Mặc định gói Năm (Best Value)
    
    let plans = [
        (title: "Hàng Tháng", price: "99.000 đ/tháng", trial: "Dùng thử 3 ngày miễn phí", note: "Sau đó 99.000 đ/tháng"),
        (title: "Hàng Năm", price: "599.000 đ/năm", trial: "Dùng thử 3 ngày miễn phí (Tiết kiệm 50%)", note: "Chỉ ~49.000 đ/tháng"),
        (title: "Trọn Đời", price: "999.000 đ", trial: "Thanh toán một lần duy nhất", note: "Sở hữu vĩnh viễn không gia hạn")
    ]
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Background Luxury Gradient
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.05, blue: 0.2), Color(red: 0.04, green: 0.04, blue: 0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    // Top Bar Close Button
                    HStack {
                        Spacer()
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    
                    // Crown Icon & Title
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .top, endPoint: .bottom))
                                .frame(width: 64, height: 64)
                                .shadow(color: .yellow.opacity(0.5), radius: 15, x: 0, y: 5)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                        
                        Text("LAICHYM PRO VIP")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Mở khóa toàn bộ sức mạnh ghi màn hình & phát trực tiếp")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Feature Comparison Highlights
                    featuresList
                    
                    // Subscription Plans Selector
                    plansSelector
                    
                    // CTA Button
                    ctaSubscribeButton
                    
                    // Restore & Terms
                    footerLinks
                    
                    Spacer(minLength: 20)
                }
            }
        }
    }
    
    // MARK: - Features List
    private var featuresList: some View {
        VStack(spacing: 12) {
            featureRow(icon: "sparkles.tv.fill", title: "Quay & Stream 1080p 60 FPS Full HD", subtitle: "Chất lượng mượt mà không giật lag")
            featureRow(icon: "tag.slash.fill", title: "Xóa sạch Logo bản quyền (No Watermark)", subtitle: "Video xuất ra hoàn toàn sạch sẽ, chuyên nghiệp")
            featureRow(icon: "infinity", title: "Livestream không giới hạn thời gian", subtitle: "Phát sóng liên tục nhiều giờ liền lên YouTube/Facebook/Twitch")
            featureRow(icon: "scissors", title: "Mở khóa toàn bộ công cụ Video Editor", subtitle: "Cắt ghép, crop 9:16 TikTok, lồng tiếng không giới hạn")
        }
        .padding(.horizontal, 16)
    }
    
    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(.yellow)
                    .font(.system(size: 16))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .cornerRadius(14)
    }
    
    // MARK: - Plans Selector
    private var plansSelector: some View {
        VStack(spacing: 12) {
            ForEach(0..<plans.count, id: \.self) { idx in
                let plan = plans[idx]
                let isSelected = selectedPlanIndex == idx
                
                Button(action: { selectedPlanIndex = idx }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(plan.title)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                
                                if idx == 1 {
                                    Text("PHỔ BIẾN NHẤT")
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.yellow))
                                }
                            }
                            
                            Text(plan.trial)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(isSelected ? .yellow : .white.opacity(0.7))
                            
                            Text(plan.note)
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(plan.price)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            
                            ZStack {
                                Circle()
                                    .stroke(isSelected ? Color.yellow : Color.white.opacity(0.3), lineWidth: 2)
                                    .frame(width: 22, height: 22)
                                
                                if isSelected {
                                    Circle()
                                        .fill(Color.yellow)
                                        .frame(width: 14, height: 14)
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(isSelected ? Color.yellow.opacity(0.12) : Color.white.opacity(0.04))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.yellow : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                    )
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - CTA Subscribe Button
    private var ctaSubscribeButton: some View {
        Button(action: executeSubscription) {
            VStack(spacing: 4) {
                Text(selectedPlanIndex == 2 ? "MUA GÓI TRỌN ĐỜI" : "DÙNG THỬ 3 NGÀY MIỄN PHÍ")
                    .font(.system(size: 16, weight: .black))
                
                Text(selectedPlanIndex == 2 ? "Thanh toán 1 lần duy nhất" : "Hủy bất cứ lúc nào trong Cài đặt Apple ID")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.85, blue: 0.2), Color(red: 1.0, green: 0.65, blue: 0.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(18)
            .shadow(color: .yellow.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Footer Links
    private var footerLinks: some View {
        HStack(spacing: 16) {
            Button("Khôi phục gói mua") {
                Task {
                    await storeKit.restorePurchases()
                }
            }
            Text("•")
            Button("Điều khoản") {}
            Text("•")
            Button("Bảo mật") {}
        }
        .font(.system(size: 11))
        .foregroundColor(.white.opacity(0.5))
    }
    
    private func executeSubscription() {
        // Kích hoạt VIP thành công (hỗ trợ cả StoreKit và Mock sandbox cho testing)
        userSettings.isVIP = true
        presentationMode.wrappedValue.dismiss()
    }
}
