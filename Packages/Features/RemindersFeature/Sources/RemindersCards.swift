import KasoDesignSystem
import RemindersDomain
import SwiftUI

struct RemindersHeaderCard: View {
    let authorizationStatus: ReminderAuthorizationStatus
    let onRequest: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("reminders.header.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)
            Text("reminders.header.subtitle", bundle: .module)
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)

            switch authorizationStatus {
            case .authorized, .provisional:
                Label {
                    Text("reminders.permission.authorized", bundle: .module)
                } icon: {
                    Image(systemName: "checkmark.seal.fill")
                }
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.positive)

            case .denied:
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Label {
                        Text("reminders.permission.denied", bundle: .module)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                    }
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.warning)
                    Text("reminders.permission.deniedHint", bundle: .module)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                }

            case .notDetermined:
                Button(action: onRequest) {
                    Text("reminders.permission.request", bundle: .module)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ReminderRowCard: View {
    let kind: ReminderKind
    let preference: ReminderPreference
    let onToggle: (Bool) -> Void
    let onTimeChange: (Int, Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: kind.iconSystemName)
                    .foregroundStyle(Color.kaso.accent)
                    .frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(kind.titleKey), bundle: .module)
                        .font(.kaso.body.weight(.semibold))
                        .foregroundStyle(Color.kaso.textPrimary)
                    Text(LocalizedStringKey(kind.descriptionKey), bundle: .module)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Toggle(
                    "",
                    isOn: Binding(
                        get: { preference.isEnabled },
                        set: { onToggle($0) }
                    )
                )
                .labelsHidden()
            }

            if preference.isEnabled && kind.isDailySchedule {
                DatePicker(
                    "reminders.time",
                    selection: Binding(
                        get: { dateFromHourMinute(preference.hour, preference.minute) },
                        set: { newValue in
                            let comps = Calendar.current
                                .dateComponents([.hour, .minute], from: newValue)
                            onTimeChange(comps.hour ?? 21, comps.minute ?? 0)
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .font(.kaso.caption)
                .padding(.leading, 36)
            }
        }
    }

    private func dateFromHourMinute(_ hour: Int, _ minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}
