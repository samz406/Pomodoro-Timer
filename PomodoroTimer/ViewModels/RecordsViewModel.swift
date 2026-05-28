import Foundation
import Combine

final class RecordsViewModel: ObservableObject {

    @Published var records: [FocusRecord] = []
    @Published var weeklyData: [(Date, Int)] = []
    @Published var monthlyData: [(Date, Int)] = []
    @Published var showMonthly: Bool = false

    var chartData: [(Date, Int)] { showMonthly ? monthlyData : weeklyData }

    init() {
        loadAll()
    }

    func loadAll() {
        records = DatabaseManager.shared.loadFocusRecords()
        weeklyData = DatabaseManager.shared.weeklyStats()
        monthlyData = DatabaseManager.shared.monthlyStats()
    }

    func deleteRecord(_ record: FocusRecord) {
        DatabaseManager.shared.deleteFocusRecord(id: record.id)
        loadAll()
    }

    // MARK: - Formatted helpers

    func formattedDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MM-dd HH:mm"
        return fmt.string(from: date)
    }

    func formattedDay(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = showMonthly ? "MM/dd" : "EEE"
        fmt.locale = Locale(identifier: "zh_CN")
        return fmt.string(from: date)
    }

    var maxChartValue: Int {
        (chartData.map(\.1).max() ?? 1)
    }
}
