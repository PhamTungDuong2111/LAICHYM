import SwiftUI

// MARK: - Settings, Language & Control Center Guide View
public struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var userSettings = UserSettings.shared
    @ObservedObject var lang = LanguageManager.shared
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.06, green: 0.08, blue: 0.12).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Language Selection Card
                        languageSelectorCard
                        
                        // Control Center Guide Card
                        controlCenterTutorialCard
                        
                        // Video Recording Settings
                        videoSettingsCard
                        
                        // Audio Settings
                        audioSettingsCard
                        
                        // App Branding & Legal
                        appInfoCard
                        
                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }
            .navigationTitle(lang.s("settings_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(lang.s("done")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Language Selector Card
    private var languageSelectorCard: some View {
        GlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "globe")
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lang.s("settings_language"))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        Text(lang.s("settings_language_desc"))
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                HStack(spacing: 12) {
                    ForEach(AppLanguage.allCases) { item in
                        let isSelected = lang.currentLanguage == item
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                userSettings.language = item
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text(item.flag)
                                    .font(.system(size: 18))
                                Text(item.title)
                                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                            }
                            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                isSelected ?
                                LinearGradient(colors: [Color.blue, Color(red: 0.1, green: 0.4, blue: 0.9)], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.08)], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? Color.blue : Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Control Center Tutorial Card
    private var controlCenterTutorialCard: some View {
        GlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "hand.tap.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 20))
                    Text(lang.s("settings_control_center_title"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    tutorialStep(number: "1", text: lang.s("settings_cc_step_1"))
                    tutorialStep(number: "2", text: lang.s("settings_cc_step_2"))
                    tutorialStep(number: "3", text: lang.s("settings_cc_step_3"))
                    tutorialStep(number: "4", text: lang.s("settings_cc_step_4"))
                }
            }
        }
    }
    
    private func tutorialStep(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.red.opacity(0.8)))
            
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.75))
                .lineSpacing(2)
        }
    }
    
    // MARK: - Video Settings Card
    private var videoSettingsCard: some View {
        GlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 14) {
                Text(lang.s("settings_default_video"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                // Resolution
                HStack {
                    Text(lang.s("live_resolution"))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Picker("", selection: $userSettings.streamSettings.resolution) {
                        ForEach(VideoResolution.allCases) { res in
                            Text(res.rawValue).tag(res)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .accentColor(.red)
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // FPS
                HStack {
                    Text(lang.s("live_fps"))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Picker("", selection: $userSettings.streamSettings.fps) {
                        ForEach(VideoFPS.allCases) { fps in
                            Text(fps.title).tag(fps)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .accentColor(.red)
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // Countdown
                HStack {
                    Text(lang.s("settings_countdown"))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Picker("", selection: $userSettings.streamSettings.countdown) {
                        ForEach(CountdownTimer.allCases) { count in
                            Text(count.title).tag(count)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .accentColor(.red)
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // Watermark
                Toggle(isOn: $userSettings.showWatermark) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lang.s("settings_watermark"))
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                        Text(lang.s("settings_watermark_sub"))
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .accentColor(.red)
            }
        }
    }
    
    // MARK: - Audio Settings Card
    private var audioSettingsCard: some View {
        GlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 14) {
                Text(lang.s("settings_audio_title"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                Toggle(isOn: $userSettings.streamSettings.enableMicrophone) {
                    Text(lang.s("settings_audio_mic"))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                }
                .accentColor(.red)
                
                Divider().background(Color.white.opacity(0.1))
                
                Toggle(isOn: $userSettings.streamSettings.enableSystemAudio) {
                    Text(lang.s("settings_audio_sys"))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                }
                .accentColor(.red)
            }
        }
    }
    
    // MARK: - App Info Card
    private var appInfoCard: some View {
        GlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text(lang.s("settings_app_info"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                HStack {
                    Text(lang.s("settings_version"))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("1.0.0 (Build 1)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                HStack {
                    Text(lang.s("settings_privacy"))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                HStack {
                    Text(lang.s("settings_terms"))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
    }
}
