import Foundation
import SQLite3

// MARK: - Data Models

struct AppSettingsData {
    var interfaceName: String = "番茄时钟"
    var isAlwaysOnTop: Bool = false
    var digitColorHex: String = "#E25C43"
    var isDesktopMiniMode: Bool = false
    // Countdown settings
    var autoBreak: Bool = true
    var breakMinutes: Int = 5
    var playWhiteNoise: Bool = false
    var showSystemNotification: Bool = true
    var autoSkipBreak: Bool = false
    var timerMode: Int = 0   // 0=classic, 1=forward, 2=infinite
    // Theme
    var currentTheme: String = "tomato"
    var followSystemAppearance: Bool = true
    // System settings
    var launchAtLogin: Bool = false
    var hotkeyModifiers: Int = 0
    var hotkeyKeyCode: Int = 0
}

struct FocusRecord: Identifiable {
    var id: Int64
    var startTime: Date
    var endTime: Date?
    var durationMinutes: Int
    var status: String // COMPLETED, INTERRUPTED
}

struct CountdownPresetData: Identifiable {
    var id: Int64 { presetId }
    var presetId: Int64
    var minutesValue: Int
    var isDefault: Bool
    var lastUsedAt: Date?
}

struct StatsData {
    var todayCount: Int
    var totalMinutes: Int
    var streakDays: Int
}

// MARK: - Database Manager

final class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?

    private init() {
        openDatabase()
        createTables()
        seedDefaults()
    }

    // MARK: - Setup

    private func dbPath() -> String {
        guard let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return NSTemporaryDirectory() + "pomodoro.db"
        }
        let appDir = dir.appendingPathComponent("PomodoroTimer")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("pomodoro.db").path
    }

    private func openDatabase() {
        let path = dbPath()
        guard sqlite3_open(path, &db) == SQLITE_OK else {
            print("[DB] Failed to open database at \(path)")
            return
        }
        // Enable WAL mode for performance
        executeSQL("PRAGMA journal_mode=WAL;")
        executeSQL("PRAGMA synchronous=NORMAL;")
    }

    private func createTables() {
        executeSQL("""
            CREATE TABLE IF NOT EXISTS tb_focus_record (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                start_time INTEGER NOT NULL,
                end_time INTEGER,
                duration_minutes INTEGER NOT NULL DEFAULT 0,
                status TEXT NOT NULL DEFAULT 'INTERRUPTED'
            );
        """)

        executeSQL("""
            CREATE TABLE IF NOT EXISTS tb_countdown_preset (
                preset_id INTEGER PRIMARY KEY,
                minutes_value INTEGER NOT NULL,
                is_default INTEGER NOT NULL DEFAULT 0,
                last_used_at INTEGER
            );
        """)

        executeSQL("""
            CREATE TABLE IF NOT EXISTS tb_app_settings (
                id INTEGER PRIMARY KEY DEFAULT 1,
                interface_name TEXT NOT NULL DEFAULT '番茄时钟',
                is_always_on_top INTEGER NOT NULL DEFAULT 0,
                digit_color_hex TEXT NOT NULL DEFAULT '#E25C43',
                is_desktop_mini_mode INTEGER NOT NULL DEFAULT 0,
                auto_break INTEGER NOT NULL DEFAULT 1,
                break_minutes INTEGER NOT NULL DEFAULT 5,
                play_white_noise INTEGER NOT NULL DEFAULT 0,
                show_system_notification INTEGER NOT NULL DEFAULT 1,
                auto_skip_break INTEGER NOT NULL DEFAULT 0,
                timer_mode INTEGER NOT NULL DEFAULT 0,
                current_theme TEXT NOT NULL DEFAULT 'tomato',
                follow_system_appearance INTEGER NOT NULL DEFAULT 1,
                launch_at_login INTEGER NOT NULL DEFAULT 0,
                hotkey_modifiers INTEGER NOT NULL DEFAULT 0,
                hotkey_key_code INTEGER NOT NULL DEFAULT 0
            );
        """)
    }

    private func seedDefaults() {
        let presetCount = queryInt("SELECT COUNT(*) FROM tb_countdown_preset") ?? 0
        if presetCount == 0 {
            executeSQL("INSERT INTO tb_countdown_preset (preset_id, minutes_value, is_default) VALUES (1, 25, 1)")
            executeSQL("INSERT INTO tb_countdown_preset (preset_id, minutes_value, is_default) VALUES (2, 30, 1)")
            executeSQL("INSERT INTO tb_countdown_preset (preset_id, minutes_value, is_default) VALUES (3, 45, 1)")
        }

        let settingsCount = queryInt("SELECT COUNT(*) FROM tb_app_settings") ?? 0
        if settingsCount == 0 {
            executeSQL("INSERT INTO tb_app_settings (id) VALUES (1)")
        }
    }

    // MARK: - Focus Records

    func insertFocusRecord(startTime: Date, durationMinutes: Int) -> Int64 {
        let ts = Int64(startTime.timeIntervalSince1970)
        executeSQL(
            "INSERT INTO tb_focus_record (start_time, duration_minutes, status) VALUES (\(ts), \(durationMinutes), 'INTERRUPTED')"
        )
        return sqlite3_last_insert_rowid(db)
    }

    func updateFocusRecord(id: Int64, endTime: Date, durationMinutes: Int, status: String) {
        let ts = Int64(endTime.timeIntervalSince1970)
        let safeStatus = status == "COMPLETED" ? "COMPLETED" : "INTERRUPTED"
        executeSQL(
            "UPDATE tb_focus_record SET end_time = \(ts), duration_minutes = \(durationMinutes), status = '\(safeStatus)' WHERE id = \(id)"
        )
    }

    func deleteFocusRecord(id: Int64) {
        executeSQL("DELETE FROM tb_focus_record WHERE id = \(id)")
    }

    func loadFocusRecords() -> [FocusRecord] {
        var records: [FocusRecord] = []
        let sql = "SELECT id, start_time, end_time, duration_minutes, status FROM tb_focus_record ORDER BY start_time DESC"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return records }
        defer { sqlite3_finalize(stmt) }

        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let startTs = sqlite3_column_int64(stmt, 1)
            let endTs = sqlite3_column_int64(stmt, 2)
            let duration = Int(sqlite3_column_int(stmt, 3))
            let statusPtr = sqlite3_column_text(stmt, 4)
            let status = statusPtr.map { String(cString: $0) } ?? "INTERRUPTED"

            let startTime = Date(timeIntervalSince1970: TimeInterval(startTs))
            let endTime = endTs > 0 ? Date(timeIntervalSince1970: TimeInterval(endTs)) : nil
            records.append(FocusRecord(id: id, startTime: startTime, endTime: endTime, durationMinutes: duration, status: status))
        }
        return records
    }

    // MARK: - Statistics

    func loadStats() -> StatsData {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let todayTs = Int64(today.timeIntervalSince1970)
        let tomorrowTs = todayTs + 86400

        let todayCount = queryInt(
            "SELECT COUNT(*) FROM tb_focus_record WHERE status='COMPLETED' AND start_time>=\(todayTs) AND start_time<\(tomorrowTs)"
        ) ?? 0

        let totalMinutes = queryInt(
            "SELECT COALESCE(SUM(duration_minutes),0) FROM tb_focus_record WHERE status='COMPLETED'"
        ) ?? 0

        return StatsData(todayCount: todayCount, totalMinutes: totalMinutes, streakDays: calculateStreak())
    }

    private func calculateStreak() -> Int {
        let cal = Calendar.current
        var streak = 0
        var checkDate = cal.startOfDay(for: Date())

        // Allow today to be incomplete – start from yesterday if today has 0
        for offset in 0..<365 {
            let startTs = Int64(checkDate.timeIntervalSince1970)
            let endTs = startTs + 86400
            let count = queryInt(
                "SELECT COUNT(*) FROM tb_focus_record WHERE status='COMPLETED' AND start_time>=\(startTs) AND start_time<\(endTs)"
            ) ?? 0
            if count > 0 {
                streak += 1
                checkDate = cal.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                if offset == 0 {
                    // Today is empty, try yesterday
                    checkDate = cal.date(byAdding: .day, value: -1, to: checkDate)!
                    continue
                }
                break
            }
        }
        return streak
    }

    func weeklyStats() -> [(Date, Int)] {
        let cal = Calendar.current
        var result: [(Date, Int)] = []
        let today = cal.startOfDay(for: Date())

        for i in 0..<7 {
            guard let date = cal.date(byAdding: .day, value: -6 + i, to: today) else { continue }
            let startTs = Int64(date.timeIntervalSince1970)
            let endTs = startTs + 86400
            let minutes = queryInt(
                "SELECT COALESCE(SUM(duration_minutes),0) FROM tb_focus_record WHERE status='COMPLETED' AND start_time>=\(startTs) AND start_time<\(endTs)"
            ) ?? 0
            result.append((date, minutes))
        }
        return result
    }

    func monthlyStats() -> [(Date, Int)] {
        let cal = Calendar.current
        var result: [(Date, Int)] = []
        let today = cal.startOfDay(for: Date())

        for i in 0..<30 {
            guard let date = cal.date(byAdding: .day, value: -29 + i, to: today) else { continue }
            let startTs = Int64(date.timeIntervalSince1970)
            let endTs = startTs + 86400
            let minutes = queryInt(
                "SELECT COALESCE(SUM(duration_minutes),0) FROM tb_focus_record WHERE status='COMPLETED' AND start_time>=\(startTs) AND start_time<\(endTs)"
            ) ?? 0
            result.append((date, minutes))
        }
        return result
    }

    // MARK: - App Settings

    func loadAppSettings() -> AppSettingsData {
        var s = AppSettingsData()
        let sql = """
            SELECT interface_name, is_always_on_top, digit_color_hex, is_desktop_mini_mode,
                   auto_break, break_minutes, play_white_noise, show_system_notification,
                   auto_skip_break, timer_mode, current_theme, follow_system_appearance,
                   launch_at_login, hotkey_modifiers, hotkey_key_code
            FROM tb_app_settings WHERE id=1
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return s }
        defer { sqlite3_finalize(stmt) }

        if sqlite3_step(stmt) == SQLITE_ROW {
            if let p = sqlite3_column_text(stmt, 0)  { s.interfaceName = String(cString: p) }
            s.isAlwaysOnTop         = sqlite3_column_int(stmt, 1) != 0
            if let p = sqlite3_column_text(stmt, 2)  { s.digitColorHex = String(cString: p) }
            s.isDesktopMiniMode     = sqlite3_column_int(stmt, 3) != 0
            s.autoBreak             = sqlite3_column_int(stmt, 4) != 0
            s.breakMinutes          = Int(sqlite3_column_int(stmt, 5))
            s.playWhiteNoise        = sqlite3_column_int(stmt, 6) != 0
            s.showSystemNotification = sqlite3_column_int(stmt, 7) != 0
            s.autoSkipBreak         = sqlite3_column_int(stmt, 8) != 0
            s.timerMode             = Int(sqlite3_column_int(stmt, 9))
            if let p = sqlite3_column_text(stmt, 10) { s.currentTheme = String(cString: p) }
            s.followSystemAppearance = sqlite3_column_int(stmt, 11) != 0
            s.launchAtLogin         = sqlite3_column_int(stmt, 12) != 0
            s.hotkeyModifiers       = Int(sqlite3_column_int(stmt, 13))
            s.hotkeyKeyCode         = Int(sqlite3_column_int(stmt, 14))
        }
        return s
    }

    func saveAppSettings(_ s: AppSettingsData) {
        let name = s.interfaceName.replacingOccurrences(of: "'", with: "''")
        let color = s.digitColorHex.replacingOccurrences(of: "'", with: "''")
        let theme = s.currentTheme.replacingOccurrences(of: "'", with: "''")
        executeSQL("""
            UPDATE tb_app_settings SET
                interface_name='\(name)',
                is_always_on_top=\(s.isAlwaysOnTop ? 1 : 0),
                digit_color_hex='\(color)',
                is_desktop_mini_mode=\(s.isDesktopMiniMode ? 1 : 0),
                auto_break=\(s.autoBreak ? 1 : 0),
                break_minutes=\(s.breakMinutes),
                play_white_noise=\(s.playWhiteNoise ? 1 : 0),
                show_system_notification=\(s.showSystemNotification ? 1 : 0),
                auto_skip_break=\(s.autoSkipBreak ? 1 : 0),
                timer_mode=\(s.timerMode),
                current_theme='\(theme)',
                follow_system_appearance=\(s.followSystemAppearance ? 1 : 0),
                launch_at_login=\(s.launchAtLogin ? 1 : 0),
                hotkey_modifiers=\(s.hotkeyModifiers),
                hotkey_key_code=\(s.hotkeyKeyCode)
            WHERE id=1
        """)
    }

    // MARK: - Presets

    func loadPresets() -> [CountdownPresetData] {
        var presets: [CountdownPresetData] = []
        let sql = "SELECT preset_id, minutes_value, is_default, last_used_at FROM tb_countdown_preset ORDER BY preset_id"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return presets }
        defer { sqlite3_finalize(stmt) }

        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let minutes = Int(sqlite3_column_int(stmt, 1))
            let isDefault = sqlite3_column_int(stmt, 2) != 0
            let lastTs = sqlite3_column_int64(stmt, 3)
            let lastUsed = lastTs > 0 ? Date(timeIntervalSince1970: TimeInterval(lastTs)) : nil
            presets.append(CountdownPresetData(presetId: id, minutesValue: minutes, isDefault: isDefault, lastUsedAt: lastUsed))
        }
        return presets
    }

    func updatePresetLastUsed(presetId: Int64) {
        let ts = Int64(Date().timeIntervalSince1970)
        executeSQL("UPDATE tb_countdown_preset SET last_used_at=\(ts) WHERE preset_id=\(presetId)")
    }

    // MARK: - Data Management

    func resetAllData() {
        executeSQL("DELETE FROM tb_focus_record")
        executeSQL("DELETE FROM tb_countdown_preset")
        executeSQL("""
            UPDATE tb_app_settings SET
                interface_name='番茄时钟', is_always_on_top=0, digit_color_hex='#E25C43',
                is_desktop_mini_mode=0, auto_break=1, break_minutes=5, play_white_noise=0,
                show_system_notification=1, auto_skip_break=0, timer_mode=0,
                current_theme='tomato', follow_system_appearance=1,
                launch_at_login=0, hotkey_modifiers=0, hotkey_key_code=0
            WHERE id=1
        """)
        executeSQL("INSERT INTO tb_countdown_preset (preset_id, minutes_value, is_default) VALUES (1, 25, 1)")
        executeSQL("INSERT INTO tb_countdown_preset (preset_id, minutes_value, is_default) VALUES (2, 30, 1)")
        executeSQL("INSERT INTO tb_countdown_preset (preset_id, minutes_value, is_default) VALUES (3, 45, 1)")
    }

    func exportData() -> [String: Any] {
        let records = loadFocusRecords()
        let recordsArr: [[String: Any]] = records.map { r in
            var dict: [String: Any] = [
                "id": r.id,
                "start_time": r.startTime.timeIntervalSince1970,
                "duration_minutes": r.durationMinutes,
                "status": r.status
            ]
            if let end = r.endTime {
                dict["end_time"] = end.timeIntervalSince1970
            }
            return dict
        }
        let s = loadAppSettings()
        return [
            "focus_records": recordsArr,
            "settings": [
                "interface_name": s.interfaceName,
                "digit_color_hex": s.digitColorHex,
                "is_always_on_top": s.isAlwaysOnTop,
                "current_theme": s.currentTheme
            ],
            "exported_at": Date().timeIntervalSince1970
        ]
    }

    // MARK: - Private Helpers

    @discardableResult
    private func executeSQL(_ sql: String) -> Bool {
        var errMsg: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(db, sql, nil, nil, &errMsg)
        if result != SQLITE_OK, let msg = errMsg {
            print("[DB] SQL Error: \(String(cString: msg))")
            sqlite3_free(errMsg)
            return false
        }
        return true
    }

    private func queryInt(_ sql: String) -> Int? {
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK,
              sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        return Int(sqlite3_column_int(stmt, 0))
    }

    deinit {
        sqlite3_close(db)
    }
}
