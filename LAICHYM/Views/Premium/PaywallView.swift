import SwiftUI

// MARK: - About & Features Showcase (100% Free Forever with Bilingual Support)
public struct PaywallView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var userSettings = UserSettings.shared
    @ObservedObject var lang = LanguageManager.shared
    
    public init() {}
    
    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.15, blue: 0.1), Color(red: 0.04, green: 0.06, blue: 0.1)],
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
                                .fill(LinearGradient(colors: [Color.green, Color(red: 0.1, green: 0.7, blue: 0.4)], startPoint: .top, endPoint: .bottom))
                                .frame(width: 64, height: 64)
                                .shadow(color: .green.opacity(0.4), radius: 15, x: 0, y: 5)
                            
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                        
                        Text(lang.s("pw_title"))
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(lang.s("pw_subtitle"))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Feature List (All Free)
                    featuresList
                    
                    // Lifetime Free Badge Card
                    freeBadgeCard
                    
                    // CTA Button
                    ctaUseNowButton
                    
                    Spacer(minLength: 20)
                }
            }
        }
    }
    
    // MARK: - Features List
    private var featuresList: some View {
        VStack(spacing: 12) {
            featureRow(icon: "sparkles.tv.fill", title: lang.s("pw_feat1_title"), subtitle: lang.s("pw_feat1_sub"))
            featureRow(icon: "tag.slash.fill", title: lang.s("pw_feat2_title"), subtitle: lang.s("pw_feat2_sub"))
            featureRow(icon: "antenna.radiowaves.left.and.right", title: lang.s("pw_feat3_title"), subtitle: lang.s("pw_feat3_sub"))
            featureRow(icon: "scissors", title: lang.s("pw_feat4_title"), subtitle: lang.s("pw_feat4_sub"))
        }
        .padding(.horizontal, 16)
    }
    
    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(.green)
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
    
    // MARK: - Free Badge Card
    private var freeBadgeCard: some View {
        GlassCard(cornerRadius: 16) {
            HStack(spacing: 12) {
                Image(systemName: "gift.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(lang.s("pw_lifetime_badge"))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text(lang.s("pw_lifetime_desc"))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - CTA Use Now Button
    private var ctaUseNowButton: some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Text(lang.s("pw_start_btn"))
                .font(.system(size: 15, weight: .black))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [Color.green, Color(red: 0.1, green: 0.6, blue: 0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .green.opacity(0.4), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 16)
    }
}
