import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var timerVM: TimerViewModel
    @StateObject private var hotkeyRecorder = HotkeyRecorder()
    @State private var settings = AppSettingsData()
    @State private var showResetAlert = false
    @State private var showExportSuccess = false
    @State private var hotkeyDisplay = "未设置"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // System section
                SectionHeader(title: "系统", icon: "gearshape")

                VStack(spacing: 1) {
                    SettingsRow {
                        HStack {
                            Label("登录 macOS 时自动启动", systemImage: "power")
                            Spacer()
                            Toggle("", isOn: $settings.launchAtLogin)
                                .labelsHidden()
                                .onChange(of: settings.launchAtLogin) { val in
                                    LaunchAtLoginHelper.setLaunchAtLogin(enabled: val)
                                    saveSettings()
                                }
                        }
                    }
                }
                .background(Color.primary.opacity(0.04))
                .cornerRadius(12)

                Divider()

                // Hotkey section
                SectionHeader(title: "全局快捷键", icon: "keyboard")

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("暂停 / 启动计时", systemImage: "command.circle")
                        Spacer()
                        Button(hotkeyRecorder.isRecording ? "按下快捷键..." : hotkeyDisplay) {
                            hotkeyRecorder.startRecording { modifiers, keyCode, display in
                                settings.hotkeyModifiers = modifiers
                                settings.hotkeyKeyCode = keyCode
                                hotkeyDisplay = display
                                saveSettings()
                                AppDelegate.shared?.setupHotkey(modifiers: modifiers, keyCode: keyCode)
                            }
                        }
                        .foregroundColor(hotkeyRecorder.isRecording ? .accentColor : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(8)

                        if settings.hotkeyKeyCode != 0 {
                            Button {
                                settings.hotkeyKeyCode = 0
                                settings.hotkeyModifiers = 0
                                hotkeyDisplay = "未设置"
                                saveSettings()
                                AppDelegate.shared?.setupHotkey(modifiers: 0, keyCode: 0)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("示例：⌥⌘P 快速暂停/启动计时器（点击按钮后按下快捷键组合）")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.primary.opacity(0.04))
                .cornerRadius(12)

                Divider()

                // Data management
                SectionHeader(title: "本地数据管理", icon: "externaldrive")

                HStack(spacing: 12) {
                    // Export
                    Button {
                        exportData()
                    } label: {
                        Label("导出备份数据", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)

                    // Reset
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("重置全量数据", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
                .padding()
                .background(Color.primary.opacity(0.04))
                .cornerRadius(12)

                Divider()

                // About
                SectionHeader(title: "关于", icon: "info.circle")
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("版本").foregroundColor(.secondary)
                        Spacer()
                        Text("1.0.0")
                    }
                    HStack {
                        Text("数据存储").foregroundColor(.secondary)
                        Spacer()
                        Text("本地 SQLite（无网络）")
                    }
                    HStack {
                        Text("系统要求").foregroundColor(.secondary)
                        Spacer()
                        Text("macOS 12.0+")
                    }
                }
                .padding()
                .background(Color.primary.opacity(0.04))
                .cornerRadius(12)

                Spacer()
            }
            .padding(30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { loadSettings() }
        .alert("确认重置全量数据", isPresented: $showResetAlert) {
            Button("重置", role: .destructive) {
                DatabaseManager.shared.resetAllData()
                timerVM.loadSettings()
                timerVM.loadStats()
                timerVM.reset()
                loadSettings()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("此操作将清空所有专注记录并将设置恢复为出厂状态，操作不可撤销。")
        }
        .alert("导出成功", isPresented: $showExportSuccess) {
            Button("好的") {}
        } message: {
            Text("数据已成功导出到您选择的位置。")
        }
    }

    // MARK: - Helpers

    private func loadSettings() {
        settings = DatabaseManager.shared.loadAppSettings()
        if settings.hotkeyKeyCode != 0 {
            hotkeyDisplay = HotkeyManager.displayString(modifiers: UInt32(settings.hotkeyModifiers),
                                                         keyCode: UInt32(settings.hotkeyKeyCode))
        }
    }

    private func saveSettings() {
        DatabaseManager.shared.saveAppSettings(settings)
        timerVM.loadSettings()
    }

    private func exportData() {
        let data = DatabaseManager.shared.exportData()
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted) else { return }

        let panel = NSSavePanel()
        panel.title = "导出番茄时钟数据"
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "pomodoro_backup.json"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try jsonData.write(to: url)
                DispatchQueue.main.async { showExportSuccess = true }
            } catch {
                print("[Export] Failed: \(error)")
            }
        }
    }
}

// MARK: - Settings Row

struct SettingsRow<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding()
    }
}

// MARK: - Hotkey Recorder

/// Uses NSEvent local monitor to capture the next key combination pressed.
final class HotkeyRecorder: ObservableObject {
    @Published var isRecording = false
    private var monitor: Any?

    func startRecording(completion: @escaping (Int, Int, String) -> Void) {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard self?.isRecording == true else { return event }
            // Escape cancels recording
            if event.keyCode == 53 {
                self?.stopRecording()
                completion(0, 0, "未设置")
                return nil
            }
            // Require at least one modifier key (not just alphanumeric)
            let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])
            guard !mods.isEmpty else { return event }

            let modRaw = Int(event.modifierFlags.rawValue)
            let keyCode = Int(event.keyCode)
            let display = HotkeyManager.displayString(
                modifiers: UInt32(event.modifierFlags.rawValue),
                keyCode: UInt32(event.keyCode)
            )
            self?.stopRecording()
            completion(modRaw, keyCode, display)
            return nil
        }
    }

    func stopRecording() {
        isRecording = false
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    deinit { stopRecording() }
}
