import SwiftUI

// MARK: - Main Tab ContentView with Bilingual Support
public struct ContentView: View {
    @State private var selectedTab: Int = 0
    @ObservedObject var faceCam = FaceCamService.shared
    @ObservedObject var lang = LanguageManager.shared
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Switcher
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)
                
                LivestreamView()
                    .tag(1)
                
                RecordingsGalleryView()
                    .tag(2)
                
                SettingsView()
                    .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            // Custom Glassmorphic Tab Bar
            customTabBar
            
            // Global Floating FaceCam (if enabled anywhere in app)
            FloatingFaceCamView()
        }
    }
    
    // MARK: - Custom Tab Bar
    private var customTabBar: some View {
        HStack {
            tabItem(index: 0, icon: "record.circle", selectedIcon: "record.circle.fill", title: lang.s("tab_home"))
            Spacer()
            tabItem(index: 1, icon: "antenna.radiowaves.left.and.right", selectedIcon: "antenna.radiowaves.left.and.right", title: lang.s("tab_live"))
            Spacer()
            tabItem(index: 2, icon: "folder", selectedIcon: "folder.fill", title: lang.s("tab_library"))
            Spacer()
            tabItem(index: 3, icon: "gearshape", selectedIcon: "gearshape.fill", title: lang.s("tab_settings"))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            Color(red: 0.08, green: 0.1, blue: 0.15).opacity(0.95)
                .background(.ultraThinMaterial)
        )
        .cornerRadius(28)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 5)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
    
    private func tabItem(index: Int, icon: String, selectedIcon: String, title: String) -> some View {
        let isSelected = selectedTab == index
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = index
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? selectedIcon : icon)
                    .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .red : .white.opacity(0.5))
                    .scaleEffect(isSelected ? 1.15 : 1.0)
                
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
            }
            .frame(width: 60)
        }
    }
}
