import SwiftUI

// MARK: - Theme Definition

struct AppTheme: Identifiable {
    let id: String
    let name: String
    let primaryColor: Color
    let accentColor: Color
    let description: String
}

extension AppTheme {
    static let allThemes: [AppTheme] = [
        AppTheme(id: "tomato",    name: "经典番茄红",  primaryColor: Color(hex: "#E25C43") ?? .red,    accentColor: Color(hex: "#FF7043") ?? .orange, description: "温暖专注，经典配色"),
        AppTheme(id: "geek",      name: "极客复古绿",  primaryColor: Color(hex: "#43A047") ?? .green,  accentColor: Color(hex: "#66BB6A") ?? .green,  description: "终端风格，极简复古"),
        AppTheme(id: "deep_space",name: "深空冷峻蓝",  primaryColor: Color(hex: "#1976D2") ?? .blue,   accentColor: Color(hex: "#42A5F5") ?? .blue,   description: "沉静深邃，专注利器"),
        AppTheme(id: "midnight",  name: "暗夜极简黑",  primaryColor: Color(hex: "#424242") ?? .gray,   accentColor: Color(hex: "#757575") ?? .gray,   description: "低调极简，夜间友好"),
    ]
}

// MARK: - Theme Card

struct ThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Preview area
                ZStack {
                    theme.primaryColor.opacity(0.12)
                    VStack(spacing: 6) {
                        Circle()
                            .stroke(theme.primaryColor, lineWidth: 4)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text("25:00")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(theme.primaryColor)
                            )

                        HStack(spacing: 4) {
                            ForEach(0..<3) { _ in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(theme.primaryColor.opacity(0.5))
                                    .frame(width: 20, height: 6)
                            }
                        }
                    }
                }
                .frame(height: 120)

                // Info area
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(theme.name)
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(theme.primaryColor)
                        }
                    }
                    Text(theme.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color.primary.opacity(0.03))
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? theme.primaryColor : Color.primary.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? theme.primaryColor.opacity(0.2) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Theme View

struct ThemeView: View {
    @EnvironmentObject var timerVM: TimerViewModel
    @State private var currentTheme: String = "tomato"
    @State private var followSystem: Bool = true

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeader(title: "主题配色", icon: "paintbrush.fill")

                // System appearance toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("紧随 macOS 系统外观切换")
                            .font(.system(size: 14))
                        Text("开启后，深色模式下自动使用毛玻璃深灰背景")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $followSystem)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .onChange(of: followSystem) { val in
                            saveTheme()
                        }
                }
                .padding()
                .background(Color.primary.opacity(0.04))
                .cornerRadius(12)

                // Theme grid
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(AppTheme.allThemes) { theme in
                        ThemeCard(
                            theme: theme,
                            isSelected: currentTheme == theme.id
                        ) {
                            currentTheme = theme.id
                            timerVM.digitColorHex = theme.primaryColor.toHex()
                            timerVM.saveSettings()
                            saveTheme()
                        }
                    }
                }

                Spacer()
            }
            .padding(30)
        }
        .onAppear {
            let s = DatabaseManager.shared.loadAppSettings()
            currentTheme = s.currentTheme
            followSystem = s.followSystemAppearance
        }
        .preferredColorScheme(followSystem ? nil : .light)
    }

    private func saveTheme() {
        var s = DatabaseManager.shared.loadAppSettings()
        s.currentTheme = currentTheme
        s.followSystemAppearance = followSystem
        DatabaseManager.shared.saveAppSettings(s)
    }
}
