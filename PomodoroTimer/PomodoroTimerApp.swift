import SwiftUI
import UserNotifications

@main
struct PomodoroTimerApp: App {

    @StateObject private var timerVM = TimerViewModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timerVM)
                .frame(minWidth: 820, minHeight: 560)
                .onAppear {
                    // Pass timerVM reference to delegate for hotkey support
                    AppDelegate.shared?.timerVM = timerVM
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AppDelegate?
    weak var timerVM: TimerViewModel?

    private var hotkeyManager: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        UNUserNotificationCenter.current().delegate = self

        // Style the window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.configureWindow()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func configureWindow() {
        guard let window = NSApp.windows.first else { return }
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.isMovableByWindowBackground = true
        window.setFrameAutosaveName("MainWindow")

        let settings = DatabaseManager.shared.loadAppSettings()
        if settings.isAlwaysOnTop {
            window.level = .floating
        }
    }

    func setupHotkey(modifiers: Int, keyCode: Int) {
        hotkeyManager?.unregister()
        guard keyCode != 0 else { return }
        hotkeyManager = HotkeyManager(modifiers: UInt32(modifiers), keyCode: UInt32(keyCode)) { [weak self] in
            DispatchQueue.main.async { self?.timerVM?.startOrPause() }
        }
        hotkeyManager?.register()
    }
}

// MARK: - Notification Delegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
