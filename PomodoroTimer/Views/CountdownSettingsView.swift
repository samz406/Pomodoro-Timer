import SwiftUI

struct CountdownSettingsView: View {
    @EnvironmentObject var vm: TimerViewModel

    private let timerModes = ["经典番茄（倒计时）", "正向流逝计时", "无限循环模式"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // Header
                SectionHeader(title: "计时模式", icon: "clock.arrow.circlepath")

                // Timer mode picker
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(timerModes.enumerated()), id: \.offset) { index, mode in
                        ModeRow(label: mode, isSelected: vm.timerMode == index) {
                            vm.timerMode = index
                            vm.saveSettings()
                        }
                    }
                }
                .padding()
                .background(Color.primary.opacity(0.04))
                .cornerRadius(12)

                Divider()

                // Break settings
                SectionHeader(title: "结束行为规则", icon: "bell.and.waves.left.and.right")

                VStack(alignment: .leading, spacing: 16) {
                    // Auto break toggle
                    SettingToggleRow(
                        label: "倒计时完毕后自动进入休息",
                        isOn: $vm.autoBreak
                    ) { vm.saveSettings() }

                    if vm.autoBreak {
                        HStack {
                            Text("休息时长")
                                .foregroundColor(.secondary)
                            Spacer()
                            Stepper("\(vm.breakMinutes) 分钟",
                                    value: $vm.breakMinutes,
                                    in: 1...30,
                                    step: 1) { _ in vm.saveSettings() }
                        }
                        .padding(.leading, 24)
                    }

                    Divider().padding(.leading, 24)

                    // Notification
                    SettingToggleRow(
                        label: "触发 macOS 系统横幅通知",
                        isOn: $vm.showSystemNotification
                    ) { vm.saveSettings() }

                    Divider().padding(.leading, 24)

                    // Auto skip break
                    SettingToggleRow(
                        label: "自动跳过休息（休息后自动开始下一轮）",
                        isOn: $vm.autoSkipBreak
                    ) { vm.saveSettings() }
                }
                .padding()
                .background(Color.primary.opacity(0.04))
                .cornerRadius(12)

                Spacer()
            }
            .padding(30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Helpers

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text(title)
                .font(.title3.weight(.semibold))
        }
    }
}

struct ModeRow: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                Text(label)
                    .foregroundColor(.primary)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

struct SettingToggleRow: View {
    let label: String
    @Binding var isOn: Bool
    let onChange: () -> Void

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(label)
        }
        .toggleStyle(.switch)
        .onChange(of: isOn) { _ in onChange() }
    }
}
