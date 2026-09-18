import AppKit
import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var store: CounterStore

    @State private var isWeeklyEditing = false
    @State private var weeklyDraft = ""
    @State private var weeklyOriginalValue = 0
    @FocusState private var weeklyFieldFocused: Bool

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "M月d日EEE"
        return formatter
    }()

    private var canvasColor: Color {
        colorScheme == .dark
            ? Color(nsColor: .windowBackgroundColor)
            : Color(red: 0.969, green: 0.976, blue: 0.988)
    }

    private var surfaceColor: Color {
        colorScheme == .dark
            ? Color(nsColor: .controlBackgroundColor)
            : Color(nsColor: .textBackgroundColor)
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text("今日")
                    .font(.system(size: 26, weight: .semibold))

                Spacer()

                Text(Self.dateFormatter.string(from: store.currentDate))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 18) {
                CounterCard(
                    title: "GPT-5.6 Pro",
                    dailyLabel: "今日",
                    dailyValue: store.daily56,
                    onIncrement: {
                        finishWeeklyEditing()
                        store.incrementDaily56()
                    },
                    onDecrement: {
                        finishWeeklyEditing()
                        store.decrementDaily56()
                    },
                    onClear: {
                        finishWeeklyEditing()
                        store.clearDaily56()
                    }
                ) {
                    Text("今日")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.secondary)
                }

                CounterCard(
                    title: "GPT-6 Pro",
                    dailyLabel: "今日",
                    dailyValue: store.daily6,
                    onIncrement: {
                        finishWeeklyEditing()
                        store.incrementDaily6()
                    },
                    onDecrement: {
                        finishWeeklyEditing()
                        store.decrementDaily6()
                    },
                    onClear: {
                        finishWeeklyEditing()
                        store.clearDaily6()
                    }
                ) {
                    WeeklyCounterEditor(
                        weeklyValue: store.weekly6,
                        isEditing: $isWeeklyEditing,
                        weeklyDraft: $weeklyDraft,
                        isFocused: $weeklyFieldFocused,
                        onBegin: beginWeeklyEditing,
                        onCommit: finishWeeklyEditing,
                        onCancel: cancelWeeklyEditing
                    )
                }
            }

            HStack {
                Text("今日合计")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("\(store.dailyTotal)")
                        .font(.system(size: 28, weight: .semibold))
                        .monospacedDigit()
                    Text("次")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, minHeight: 66)
            .background(surfaceColor, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.035), radius: 10, y: 3)

            HStack(spacing: 16) {
                Button("今日清零") {
                    finishWeeklyEditing()
                    store.clearToday()
                }
                .buttonStyle(SecondaryActionButtonStyle())

                Button("本周清零") {
                    finishWeeklyEditing()
                    store.clearWeekly6()
                }
                .buttonStyle(SecondaryActionButtonStyle())

                Button("撤销清零") {
                    cancelWeeklyEditing()
                    store.undoClear()
                }
                .disabled(!store.canUndoClear)
                .buttonStyle(SecondaryActionButtonStyle())
            }
        }
        .frame(maxWidth: 1000)
        .padding(.horizontal, 30)
        .padding(.top, 22)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .top)
        .background {
            canvasColor
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    finishWeeklyEditing()
                }
        }
    }

    private func beginWeeklyEditing() {
        weeklyOriginalValue = store.weekly6
        weeklyDraft = String(store.weekly6)
        isWeeklyEditing = true

        DispatchQueue.main.async {
            if isWeeklyEditing {
                weeklyFieldFocused = true
            }
        }
    }

    private func finishWeeklyEditing() {
        guard isWeeklyEditing else { return }

        let trimmedDraft = weeklyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Int(trimmedDraft) {
            let normalizedValue = max(0, value)
            if normalizedValue != weeklyOriginalValue {
                store.setWeekly6(normalizedValue)
            }
        }

        weeklyFieldFocused = false
        isWeeklyEditing = false
        weeklyDraft = String(store.weekly6)
    }

    private func cancelWeeklyEditing() {
        guard isWeeklyEditing else { return }

        weeklyDraft = String(weeklyOriginalValue)
        weeklyFieldFocused = false
        isWeeklyEditing = false
    }
}

private struct CounterCard<Accessory: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let dailyLabel: String
    let dailyValue: Int
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onClear: () -> Void
    let accessory: Accessory

    private var surfaceColor: Color {
        colorScheme == .dark
            ? Color(nsColor: .controlBackgroundColor)
            : Color(nsColor: .textBackgroundColor)
    }

    init(
        title: String,
        dailyLabel: String,
        dailyValue: Int,
        onIncrement: @escaping () -> Void,
        onDecrement: @escaping () -> Void,
        onClear: @escaping () -> Void,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.title = title
        self.dailyLabel = dailyLabel
        self.dailyValue = dailyValue
        self.onIncrement = onIncrement
        self.onDecrement = onDecrement
        self.onClear = onClear
        self.accessory = accessory()
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 23, weight: .semibold))

                    if title == "GPT-6 Pro" {
                        Text(dailyLabel)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 12)

                accessory
            }

            Spacer(minLength: 0)

            Text("\(dailyValue)")
                .font(.system(size: 78, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .frame(maxWidth: .infinity)

            Spacer(minLength: 0)

            Button("+1", action: onIncrement)
                .buttonStyle(PrimaryCounterButtonStyle())

            HStack(spacing: 16) {
                Button("-1", action: onDecrement)
                    .disabled(dailyValue == 0)
                    .buttonStyle(SecondaryActionButtonStyle())

                Button("清零", action: onClear)
                    .buttonStyle(SecondaryActionButtonStyle())
            }
        }
        .padding(23)
        .frame(maxWidth: .infinity)
        .frame(height: 330)
        .background(surfaceColor, in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.035), radius: 10, y: 3)
    }
}

private struct WeeklyCounterEditor: View {
    @Environment(\.colorScheme) private var colorScheme

    let weeklyValue: Int
    @Binding var isEditing: Bool
    @Binding var weeklyDraft: String
    let isFocused: FocusState<Bool>.Binding
    let onBegin: () -> Void
    let onCommit: () -> Void
    let onCancel: () -> Void

    private var surfaceColor: Color {
        colorScheme == .dark
            ? Color(nsColor: .controlBackgroundColor)
            : Color(nsColor: .textBackgroundColor)
    }

    var body: some View {
        Group {
            if isEditing {
                editingContent
            } else {
                normalButton
            }
        }
        .frame(width: 136, height: 72)
    }

    private var normalButton: some View {
        Button(action: onBegin) {
            VStack(alignment: .trailing, spacing: 4) {
                Text("本周")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(weeklyValue)")
                        .font(.system(size: 21, weight: .semibold))
                        .monospacedDigit()

                    Text("次")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(RoundedRectangle(cornerRadius: 14))
            .background(surfaceColor, in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.primary.opacity(0.10), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var editingContent: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("本周")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                TextField("", text: $weeklyDraft)
                    .font(.system(size: 18, weight: .semibold))
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.plain)
                    .frame(width: 50, height: 26)
                    .background(surfaceColor.opacity(colorScheme == .dark ? 0.55 : 0.72), in: RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                    }
                    .focused(isFocused)
                    .onSubmit {
                        onCommit()
                    }
                    .onExitCommand {
                        onCancel()
                    }
                    .accessibilityLabel("本周次数")

                Button(action: onCommit) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
                .accessibilityLabel("保存本周次数")

                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel("取消编辑本周次数")
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(width: 136, height: 72, alignment: .trailing)
        .background(surfaceColor, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
        }
    }
}

private struct PrimaryCounterButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 22, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: 60)
            .contentShape(RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.primary)
            .background(
                Color.accentColor.opacity(configuration.isPressed ? 0.24 : 0.16),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.accentColor.opacity(0.10), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

private struct SecondaryActionButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled

    private var surfaceColor: Color {
        colorScheme == .dark
            ? Color(nsColor: .controlBackgroundColor)
            : Color(nsColor: .textBackgroundColor)
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .medium))
            .frame(maxWidth: .infinity, minHeight: 50)
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.primary)
            .background(surfaceColor, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.10), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(isEnabled ? (configuration.isPressed ? 0.72 : 1) : 0.42)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}
