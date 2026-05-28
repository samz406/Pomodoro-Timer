import SwiftUI

enum NavPage: String, CaseIterable, Identifiable {
    case timer       = "计时"
    case countdown   = "倒计时"
    case records     = "记录"
    case theme       = "主题"
    case settings    = "设置"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .timer:     return "timer"
        case .countdown: return "clock.arrow.circlepath"
        case .records:   return "chart.bar.fill"
        case .theme:     return "paintbrush.fill"
        case .settings:  return "gearshape.fill"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var timerVM: TimerViewModel
    @State private var selectedPage: NavPage = .timer

    var body: some View {
        NavigationView {
            // Sidebar
            List(NavPage.allCases, selection: $selectedPage) { page in
                Label(page.rawValue, systemImage: page.icon)
                    .tag(page)
            }
            .listStyle(.sidebar)
            .frame(minWidth: 160, idealWidth: 180)
            .navigationTitle(timerVM.interfaceName)

            // Detail
            Group {
                switch selectedPage {
                case .timer:     TimerView()
                case .countdown: CountdownSettingsView()
                case .records:   RecordsView()
                case .theme:     ThemeView()
                case .settings:  SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .environmentObject(timerVM)
    }
}
