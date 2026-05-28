import SwiftUI

// MARK: - Ring Progress Shape

struct RingProgressShape: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 8
        path.addArc(center: center,
                    radius: radius,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(-90 + 360 * progress),
                    clockwise: false)
        return path
    }
}

// MARK: - Circular Timer View

struct CircularTimerView: View {
    @EnvironmentObject var vm: TimerViewModel
    private let ringSize: CGFloat = 260
    private let lineWidth: CGFloat = 14

    var body: some View {
        ZStack {
            // Track ring (background)
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)
                .frame(width: ringSize, height: ringSize)

            // Progress ring
            RingProgressShape(progress: vm.progress)
                .stroke(
                    vm.digitColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: ringSize, height: ringSize)
                .animation(.linear(duration: 0.3), value: vm.progress)

            // Drag thumb
            if !vm.isRunning && !vm.isPaused {
                thumbView
            }

            // Central text
            VStack(spacing: 6) {
                Text(vm.timeString)
                    .font(.system(size: 58, weight: .bold, design: .monospaced))
                    .foregroundColor(vm.digitColor)

                Text(vm.phaseLabel)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: ringSize, height: ringSize)
        .contentShape(Circle())
        .gesture(dragGesture)
    }

    // MARK: - Thumb

    private var thumbAngle: Angle {
        .degrees(-90 + vm.progress * 360)
    }

    private var thumbOffset: CGSize {
        let radius = (ringSize / 2) - lineWidth / 2
        let rad = thumbAngle.radians
        return CGSize(width: cos(rad) * radius, height: sin(rad) * radius)
    }

    private var thumbView: some View {
        Circle()
            .fill(vm.digitColor)
            .frame(width: 22, height: 22)
            .shadow(color: vm.digitColor.opacity(0.5), radius: 4)
            .offset(thumbOffset)
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                guard !vm.isRunning && !vm.isPaused else { return }
                let center = CGPoint(x: ringSize / 2, y: ringSize / 2)
                let dx = value.location.x - center.x
                let dy = value.location.y - center.y
                var angle = atan2(dy, dx) * 180 / .pi + 90
                if angle < 0 { angle += 360 }
                vm.setMinutesFromAngle(angleDegrees: Double(angle))
            }
    }
}

// MARK: - Bento Stats Card

struct BentoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(14)
    }
}

// MARK: - Right Settings Panel

struct TimerSettingsPanel: View {
    @EnvironmentObject var vm: TimerViewModel
    @State private var selectedColorHex: String = "#E25C43"

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("应用设置")
                .font(.headline)
                .foregroundColor(.secondary)

            Divider()

            // Interface name
            VStack(alignment: .leading, spacing: 6) {
                Text("应用名称").font(.caption).foregroundColor(.secondary)
                TextField("番茄时钟", text: $vm.interfaceName)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: vm.interfaceName) { _ in vm.saveSettings() }
            }

            // Digit color
            VStack(alignment: .leading, spacing: 6) {
                Text("数字颜色").font(.caption).foregroundColor(.secondary)
                HStack(spacing: 10) {
                    ForEach(colorPresets, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex) ?? .red)
                            .frame(width: 26, height: 26)
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: vm.digitColorHex == hex ? 3 : 0)
                            )
                            .shadow(radius: 2)
                            .onTapGesture {
                                vm.digitColorHex = hex
                                vm.saveSettings()
                            }
                    }
                }
            }

            // Always on top
            Toggle("窗口置顶", isOn: $vm.isAlwaysOnTop)
                .toggleStyle(.switch)
                .onChange(of: vm.isAlwaysOnTop) { _ in vm.saveSettings() }

            // Desktop mini mode
            Toggle("桌面迷你模式", isOn: $vm.isDesktopMiniMode)
                .toggleStyle(.switch)
                .onChange(of: vm.isDesktopMiniMode) { _ in vm.saveSettings() }

            Divider()

            Text("倒计时时间")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("拖动圆环或点击预设按钮调整时长（1–90 分钟）")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding()
        .frame(width: 200)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private let colorPresets = ["#E25C43", "#43A047", "#1976D2", "#7B1FA2", "#F57C00", "#00838F"]
}

// MARK: - Timer View (Main)

struct TimerView: View {
    @EnvironmentObject var vm: TimerViewModel

    var body: some View {
        HStack(spacing: 0) {
            // Main timer area
            VStack(spacing: 24) {
                // Preset buttons
                HStack(spacing: 12) {
                    ForEach(vm.defaultPresets, id: \.0) { (id, min) in
                        PresetButton(minutes: min, isSelected: vm.selectedMinutes == min && !vm.isRunning && !vm.isPaused) {
                            vm.selectPreset(id: id, minutes: min)
                        }
                    }
                }

                Spacer()

                // Ring + time display
                CircularTimerView()
                    .environmentObject(vm)

                Spacer()

                // Control buttons
                HStack(spacing: 20) {
                    // Start / Pause
                    Button(action: { vm.startOrPause() }) {
                        HStack(spacing: 8) {
                            Image(systemName: vm.isRunning ? "pause.fill" : "play.fill")
                            Text(vm.isRunning ? "暂停" : (vm.isPaused ? "继续" : "开始"))
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(vm.digitColor)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    // Reset
                    Button(action: { vm.reset() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("重置")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }

                // Bento stats
                HStack(spacing: 12) {
                    BentoCard(
                        title: "今日专注",
                        value: "\(vm.todayFocusCount) 次",
                        icon: "checkmark.seal.fill",
                        color: vm.digitColor
                    )
                    BentoCard(
                        title: "总专注时间",
                        value: vm.totalFocusTimeString,
                        icon: "clock.fill",
                        color: .orange
                    )
                    BentoCard(
                        title: "连续坚持",
                        value: "\(vm.streakDays) 天",
                        icon: "flame.fill",
                        color: .red
                    )
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 30)
            .frame(maxWidth: .infinity)

            // Right settings panel
            Divider()
            TimerSettingsPanel()
                .environmentObject(vm)
        }
    }
}

// MARK: - Preset Button

struct PresetButton: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(minutes) 分钟")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(isSelected ? Color.accentColor : Color.primary.opacity(0.08))
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}
