import Foundation
import Combine
import AppKit
import UserNotifications

enum TimerPhase {
    case focus
    case breakTime
}

final class TimerViewModel: ObservableObject {

    // MARK: - Published State

    @Published var selectedMinutes: Int = 25
    @Published var remainingSeconds: Int = 25 * 60
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var phase: TimerPhase = .focus
    @Published var progress: Double = 1.0        // 1.0 = full arc, 0.0 = empty

    // Settings (synced with DB)
    @Published var digitColorHex: String = "#E25C43"
    @Published var isAlwaysOnTop: Bool = false
    @Published var isDesktopMiniMode: Bool = false
    @Published var interfaceName: String = "番茄时钟"

    // Countdown rule settings
    @Published var autoBreak: Bool = true
    @Published var breakMinutes: Int = 5
    @Published var showSystemNotification: Bool = true
    @Published var autoSkipBreak: Bool = false
    @Published var timerMode: Int = 0   // 0=classic countdown, 1=forward elapsed, 2=infinite

    // Bento stats
    @Published var todayFocusCount: Int = 0
    @Published var totalFocusMinutes: Int = 0
    @Published var streakDays: Int = 0

    // MARK: - Private

    private var timer: Timer?
    private var sessionStart: Date?
    private var currentRecordId: Int64?
    private var elapsedSeconds: Int = 0   // used in forward (mode 1) tracking

    let defaultPresets: [(Int64, Int)] = [(1, 25), (2, 30), (3, 45)]

    // MARK: - Init

    init() {
        loadSettings()
        loadStats()
        requestNotificationPermission()
    }

    // MARK: - Preset Selection

    func selectPreset(id: Int64, minutes: Int) {
        guard !isRunning else { return }
        selectedMinutes = minutes
        remainingSeconds = minutes * 60
        progress = 1.0
        phase = .focus
        DatabaseManager.shared.updatePresetLastUsed(presetId: id)
    }

    // MARK: - Timer Control

    func startOrPause() {
        if isRunning {
            pause()
        } else if isPaused {
            resume()
        } else {
            start()
        }
    }

    func start() {
        isRunning = true
        isPaused = false
        sessionStart = Date()
        elapsedSeconds = 0

        currentRecordId = DatabaseManager.shared.insertFocusRecord(
            startTime: sessionStart!,
            durationMinutes: selectedMinutes
        )

        scheduleTimer()
    }

    func pause() {
        isRunning = false
        isPaused = true
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        isRunning = true
        isPaused = false
        scheduleTimer()
    }

    func reset() {
        if isRunning || isPaused {
            archiveCurrentRecord(as: "INTERRUPTED")
        }
        stopTimer()
        remainingSeconds = selectedMinutes * 60
        progress = 1.0
        phase = .focus
        elapsedSeconds = 0
        loadStats()
    }

    // MARK: - Drag ring adjustment

    func setMinutesFromAngle(angleDegrees: Double) {
        guard !isRunning && !isPaused else { return }
        // angle 0 = 12 o'clock, clockwise = more time
        // Map 0..360 → 1..90 minutes
        let fraction = angleDegrees / 360.0
        let minutes = max(1, min(90, Int(fraction * 90) + 1))
        selectedMinutes = minutes
        remainingSeconds = minutes * 60
        progress = 1.0
    }

    // MARK: - Computed

    var timeString: String {
        if timerMode == 1 {
            // Forward elapsed mode
            let m = elapsedSeconds / 60
            let s = elapsedSeconds % 60
            return String(format: "%02d:%02d", m, s)
        }
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var phaseLabel: String {
        switch phase {
        case .focus:     return isRunning ? "专注时间" : (isPaused ? "已暂停" : "准备开始")
        case .breakTime: return isRunning ? "休息时间" : "休息完成"
        }
    }

    var digitColor: Color {
        Color(hex: digitColorHex) ?? .red
    }

    var totalFocusTimeString: String {
        let h = totalFocusMinutes / 60
        let m = totalFocusMinutes % 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    // MARK: - Settings

    func loadSettings() {
        let s = DatabaseManager.shared.loadAppSettings()
        digitColorHex = s.digitColorHex
        isAlwaysOnTop = s.isAlwaysOnTop
        isDesktopMiniMode = s.isDesktopMiniMode
        interfaceName = s.interfaceName
        autoBreak = s.autoBreak
        breakMinutes = s.breakMinutes
        showSystemNotification = s.showSystemNotification
        autoSkipBreak = s.autoSkipBreak
        timerMode = s.timerMode
        applyWindowLevel()
    }

    func saveSettings() {
        var s = DatabaseManager.shared.loadAppSettings()
        s.digitColorHex = digitColorHex
        s.isAlwaysOnTop = isAlwaysOnTop
        s.isDesktopMiniMode = isDesktopMiniMode
        s.interfaceName = interfaceName
        s.autoBreak = autoBreak
        s.breakMinutes = breakMinutes
        s.showSystemNotification = showSystemNotification
        s.autoSkipBreak = autoSkipBreak
        s.timerMode = timerMode
        DatabaseManager.shared.saveAppSettings(s)
        applyWindowLevel()
    }

    func loadStats() {
        let stats = DatabaseManager.shared.loadStats()
        todayFocusCount = stats.todayCount
        totalFocusMinutes = stats.totalMinutes
        streakDays = stats.streakDays
    }

    // MARK: - Private

    private func scheduleTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.tick() }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func tick() {
        elapsedSeconds += 1

        switch timerMode {
        case 1:
            // Forward elapsed – run until user resets
            progress = 1.0  // ring stays full in forward mode
        case 2:
            // Infinite loop – completePhase handles state transitions, timer keeps running
            if remainingSeconds > 0 {
                remainingSeconds -= 1
                let totalSeconds = phase == .focus ? selectedMinutes * 60 : breakMinutes * 60
                progress = Double(remainingSeconds) / Double(totalSeconds)
            } else {
                completePhase()
                // completePhase sets remainingSeconds and phase for next cycle
            }
        default:
            // Classic countdown
            if remainingSeconds > 0 {
                remainingSeconds -= 1
                progress = Double(remainingSeconds) / Double(selectedMinutes * 60)
            } else {
                completePhase()
            }
        }
    }

    private func completePhase() {
        switch phase {
        case .focus:
            archiveCurrentRecord(as: "COMPLETED")
            loadStats()
            sendNotification(title: "专注完成！", body: "休息一下吧，\(breakMinutes) 分钟后继续。")

            if autoBreak || timerMode == 2 {
                // Enter break phase, keep timer running
                phase = .breakTime
                remainingSeconds = breakMinutes * 60
                progress = 1.0
                // In infinite mode, the timer continues ticking
                // In classic/forward mode with autoBreak, same behavior
            } else {
                stopTimer()
                remainingSeconds = selectedMinutes * 60
                progress = 1.0
            }

        case .breakTime:
            sendNotification(title: "休息结束", body: "开始新一轮专注！")
            if autoSkipBreak || timerMode == 2 {
                // Auto-start next focus session
                phase = .focus
                remainingSeconds = selectedMinutes * 60
                progress = 1.0
                sessionStart = Date()
                currentRecordId = DatabaseManager.shared.insertFocusRecord(
                    startTime: sessionStart!,
                    durationMinutes: selectedMinutes
                )
                // Timer keeps running in infinite mode
                if !isRunning {
                    scheduleTimer()
                    isRunning = true
                    isPaused = false
                }
            } else {
                stopTimer()
                phase = .focus
                remainingSeconds = selectedMinutes * 60
                progress = 1.0
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        currentRecordId = nil
        sessionStart = nil
        elapsedSeconds = 0
    }

    private func archiveCurrentRecord(as status: String) {
        guard let id = currentRecordId, let start = sessionStart else { return }
        let actualMinutes = max(1, Int(Date().timeIntervalSince(start) / 60))
        DatabaseManager.shared.updateFocusRecord(
            id: id, endTime: Date(), durationMinutes: actualMinutes, status: status
        )
        currentRecordId = nil
        sessionStart = nil
    }

    private func applyWindowLevel() {
        DispatchQueue.main.async {
            NSApp.windows.forEach { window in
                window.level = self.isAlwaysOnTop ? .floating : .normal
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendNotification(title: String, body: String) {
        guard showSystemNotification else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }
}
