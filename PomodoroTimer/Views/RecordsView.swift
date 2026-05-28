import SwiftUI

// MARK: - Simple bar chart (no Charts framework dependency, macOS 12 compatible)

struct BarChartView: View {
    let data: [(Date, Int)]
    let maxValue: Int
    let labelFormatter: (Date) -> String
    let barColor: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                VStack(spacing: 4) {
                    Text("\(item.1)")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .opacity(item.1 > 0 ? 1 : 0)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(
                            width: 28,
                            height: max(4, CGFloat(item.1) / CGFloat(max(maxValue, 1)) * 100)
                        )

                    Text(labelFormatter(item.0))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Records View

struct RecordsView: View {
    @EnvironmentObject var timerVM: TimerViewModel
    @StateObject private var vm = RecordsViewModel()
    @State private var selectedRecord: FocusRecord?
    @State private var showDeleteAlert = false
    @State private var recordToDelete: FocusRecord?

    var body: some View {
        VStack(spacing: 0) {
            // Charts row
            HStack(alignment: .top, spacing: 12) {
                // Weekly / Monthly bar chart
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(vm.showMonthly ? "月度专注" : "周专注（分钟）")
                            .font(.headline)
                        Spacer()
                        Picker("", selection: $vm.showMonthly) {
                            Text("周").tag(false)
                            Text("月").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 80)
                    }

                    BarChartView(
                        data: vm.chartData,
                        maxValue: vm.maxChartValue,
                        labelFormatter: vm.formattedDay,
                        barColor: timerVM.digitColor
                    )
                    .frame(height: 130)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.primary.opacity(0.04))
                .cornerRadius(14)

                // Interruption heatmap placeholder
                VStack(alignment: .leading, spacing: 10) {
                    Text("打断分布")
                        .font(.headline)
                    InterruptionHeatmap(records: vm.records)
                        .frame(height: 130)
                }
                .padding()
                .frame(width: 220)
                .background(Color.primary.opacity(0.04))
                .cornerRadius(14)
            }
            .padding()

            Divider()

            // History table
            VStack(alignment: .leading, spacing: 0) {
                // Table header
                HStack {
                    Text("开始时间").frame(width: 130, alignment: .leading)
                    Text("预计时长").frame(width: 80, alignment: .center)
                    Text("实际时长").frame(width: 80, alignment: .center)
                    Text("状态").frame(width: 80, alignment: .center)
                    Spacer()
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.03))

                Divider()

                if vm.records.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("暂无记录，完成一个番茄钟后这里会显示历史数据")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List(vm.records) { record in
                        RecordRow(record: record, formatter: vm.formattedDate)
                            .contextMenu {
                                Button(role: .destructive) {
                                    recordToDelete = record
                                    showDeleteAlert = true
                                } label: {
                                    Label("删除此条本地记录", systemImage: "trash")
                                }
                            }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { vm.loadAll() }
        .alert("确认删除", isPresented: $showDeleteAlert, presenting: recordToDelete) { rec in
            Button("删除", role: .destructive) {
                vm.deleteRecord(rec)
                timerVM.loadStats()
            }
            Button("取消", role: .cancel) {}
        } message: { _ in
            Text("此操作将从本地数据库永久删除该条记录，无法恢复。")
        }
    }
}

// MARK: - Record Row

struct RecordRow: View {
    let record: FocusRecord
    let formatter: (Date) -> String

    var body: some View {
        HStack {
            Text(formatter(record.startTime))
                .frame(width: 130, alignment: .leading)
                .font(.system(size: 13, design: .monospaced))

            Text("\(record.durationMinutes) 分钟")
                .frame(width: 80, alignment: .center)
                .font(.system(size: 13))

            let actualMins: String = {
                if let end = record.endTime {
                    let diff = Int(end.timeIntervalSince(record.startTime) / 60)
                    return "\(diff) 分钟"
                }
                return "–"
            }()
            Text(actualMins)
                .frame(width: 80, alignment: .center)
                .font(.system(size: 13))

            StatusBadge(status: record.status)
                .frame(width: 80, alignment: .center)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: String

    var body: some View {
        Text(status == "COMPLETED" ? "完成" : "打断")
            .font(.caption.weight(.semibold))
            .foregroundColor(status == "COMPLETED" ? .green : .orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background((status == "COMPLETED" ? Color.green : Color.orange).opacity(0.15))
            .cornerRadius(8)
    }
}

// MARK: - Interruption Heatmap (hour-of-day distribution)

struct InterruptionHeatmap: View {
    let records: [FocusRecord]

    private var hourCounts: [Int] {
        var counts = Array(repeating: 0, count: 24)
        for r in records where r.status == "INTERRUPTED" {
            let hour = Calendar.current.component(.hour, from: r.startTime)
            counts[hour] += 1
        }
        return counts
    }

    private var maxCount: Int { hourCounts.max() ?? 1 }

    var body: some View {
        let counts = hourCounts
        let max = max(maxCount, 1)

        VStack(alignment: .leading, spacing: 4) {
            Text("打断时段热力图")
                .font(.caption)
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 6), spacing: 2) {
                ForEach(0..<24, id: \.self) { hour in
                    let intensity = Double(counts[hour]) / Double(max)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.orange.opacity(0.15 + 0.85 * intensity))
                        .frame(height: 16)
                        .overlay(
                            Text("\(hour)")
                                .font(.system(size: 7))
                                .foregroundColor(.secondary)
                        )
                }
            }

            HStack {
                Text("低").font(.system(size: 9)).foregroundColor(.secondary)
                Spacer()
                Text("高").font(.system(size: 9)).foregroundColor(.secondary)
            }
        }
    }
}
