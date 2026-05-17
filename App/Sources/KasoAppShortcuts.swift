import AppIntents
import QuickEntryIntent

struct KasoAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogExpenseIntent(),
            phrases: [
                "Ghi chi tiêu vào \(.applicationName)",
                "Log expense in \(.applicationName)",
                "Chi tiêu \(.applicationName)",
            ],
            shortTitle: "Ghi chi tiêu",
            systemImageName: "minus.circle.fill"
        )
        AppShortcut(
            intent: LogIncomeIntent(),
            phrases: [
                "Ghi thu nhập vào \(.applicationName)",
                "Log income in \(.applicationName)",
                "Thu nhập \(.applicationName)",
            ],
            shortTitle: "Ghi thu nhập",
            systemImageName: "plus.circle.fill"
        )
    }
}
