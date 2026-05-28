import Foundation
import ServiceManagement

// MARK: - Launch At Login Helper
// Uses SMAppService (macOS 13+) with fallback for macOS 12.

enum LaunchAtLoginHelper {

    static func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            setViaAppService(enabled: enabled)
        } else {
            setViaLoginItems(enabled: enabled)
        }
    }

    static func isEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            return legacyIsEnabled()
        }
    }

    // MARK: - macOS 13+ (SMAppService)

    @available(macOS 13.0, *)
    private static func setViaAppService(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("[LaunchAtLogin] SMAppService error: \(error)")
        }
    }

    // MARK: - macOS 12 (SMLoginItemSetEnabled)

    @available(macOS, deprecated: 13.0)
    private static func setViaLoginItems(enabled: Bool) {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.samz406.PomodoroTimer"
        SMLoginItemSetEnabled(bundleID as CFString, enabled)
    }

    @available(macOS, deprecated: 13.0)
    private static func legacyIsEnabled() -> Bool {
        // Check via LaunchServices / LSSharedFileList (deprecated API)
        // For simplicity, return the stored preference
        return DatabaseManager.shared.loadAppSettings().launchAtLogin
    }
}
