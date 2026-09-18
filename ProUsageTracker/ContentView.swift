import AppKit
import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var store: CounterStore

    @State private var isWeeklyPopoverPresented = false
    @State private var weeklyDraft = ""
    @State private var weeklyOriginalValue = 0
    @State private var weeklyPopoverDismissal: WeeklyPopoverDismissal = .none

    private enum WeeklyPopoverDismissal {
        case none
        case commit
        case cancel
    }

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
                        finishWeeklyPopoverForAction()
                        store.incrementDaily56()
                    },
                    onDecrement: {
                        finishWeeklyPopoverForAction()
                        store.decrementDaily56()
                    },
                    onClear: {
                        finishWeeklyPopoverForAction()
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
                        finishWeeklyPopoverForAction()
                        store.incrementDaily6()
                    },
                    onDecrement: {
                        finishWeeklyPopoverForAction()
                        store.decrementDaily6()
                    },
                    onClear: {
                        finishWeeklyPopoverForAction()
                        store.clearDaily6()
                    }
                ) {
                    WeeklyCapsule(
                        weeklyValue: store.weekly6,
                        isPresented: $isWeeklyPopoverPresented,
                        onBegin: beginWeeklyPopover,
                        weeklyDraft: $weeklyDraft,
                        onCommit: commitWeeklyPopover,
                        onCancel: cancelWeeklyPopover
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
                    finishWeeklyPopoverForAction()
                    store.clearToday()
                }
                .buttonStyle(SecondaryActionButtonStyle())

                Button("本周清零") {
                    finishWeeklyPopoverForAction()
                    store.clearWeekly6()
                }
                .buttonStyle(SecondaryActionButtonStyle())

                Button("撤销清零") {
                    finishWeeklyPopoverForAction()
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
        .background(canvasColor.ignoresSafeArea())
        .onChange(of: isWeeklyPopoverPresented) { isPresented in
            guard !isPresented else { return }
            handleWeeklyPopoverDismissal()
        }
    }

    private func beginWeeklyPopover() {
        weeklyOriginalValue = store.weekly6
        weeklyDraft = String(store.weekly6)
        weeklyPopoverDismissal = .none
        isWeeklyPopoverPresented = true
    }

    private func commitWeeklyPopover() {
        guard isWeeklyPopoverPresented else { return }

        weeklyPopoverDismissal = .commit
        commitWeeklyDraftIfNeeded()
        isWeeklyPopoverPresented = false
    }

    private func cancelWeeklyPopover() {
        guard isWeeklyPopoverPresented else { return }

        weeklyPopoverDismissal = .cancel
        weeklyDraft = String(weeklyOriginalValue)
        isWeeklyPopoverPresented = false
    }

    private func finishWeeklyPopoverForAction() {
        guard isWeeklyPopoverPresented else { return }
        commitWeeklyPopover()
    }

    private func commitWeeklyDraftIfNeeded() {
        let trimmedDraft = weeklyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int(trimmedDraft) else {
            weeklyDraft = String(weeklyOriginalValue)
            return
        }

        let normalizedValue = max(0, value)
        if normalizedValue != weeklyOriginalValue {
            store.setWeekly6(normalizedValue)
        }
        weeklyDraft = String(store.weekly6)
    }

    // The presentation binding is the single path for a native outside dismissal.
    private func handleWeeklyPopoverDismissal() {
        switch weeklyPopoverDismissal {
        case .none:
            commitWeeklyDraftIfNeeded()
        case .commit:
            break
        case .cancel:
            weeklyDraft = String(weeklyOriginalValue)
        }

        weeklyPopoverDismissal = .none
        weeklyDraft = String(store.weekly6)
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

private struct WeeklyCapsule: View {
    let weeklyValue: Int
    @Binding var isPresented: Bool
    let onBegin: () -> Void
    @Binding var weeklyDraft: String
    let onCommit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        Button(action: onBegin) {
            HStack(spacing: 6) {
                Text("本周")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 6)

                Text("\(weeklyValue)")
                    .font(.system(size: 20, weight: .semibold))
                    .monospacedDigit()

                Text("次")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
        }
        .buttonStyle(WeeklyCapsuleButtonStyle())
        .frame(width: 136, height: 50)
        .popover(isPresented: $isPresented, attachmentAnchor: .point(.topTrailing), arrowEdge: .top) {
            WeeklyPopoverEditor(
                weeklyDraft: $weeklyDraft,
                onCommit: onCommit,
                onCancel: onCancel
            )
        }
    }
}

private struct WeeklyPopoverEditor: View {
    @Binding var weeklyDraft: String
    let onCommit: () -> Void
    let onCancel: () -> Void

    @FocusState private var fieldIsFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本周")
                .font(.system(size: 16, weight: .semibold))

            HStack(spacing: 6) {
                TextField("", text: $weeklyDraft)
                    .font(.system(size: 20, weight: .semibold))
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .focused($fieldIsFocused)
                    .onSubmit {
                        submit()
                    }
                    .onExitCommand {
                        cancel()
                    }

                Text("次")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(width: 210)
        .onAppear {
            DispatchQueue.main.async {
                fieldIsFocused = true
            }
        }
    }

    private func submit() {
        fieldIsFocused = false
        onCommit()
    }

    private func cancel() {
        fieldIsFocused = false
        onCancel()
    }
}

private struct WeeklyCapsuleButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: 50)
            .contentShape(Capsule())
            .background(
                Color.accentColor.opacity(configuration.isPressed ? 0.18 : 0.10),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(Color.accentColor.opacity(colorScheme == .dark ? 0.22 : 0.14), lineWidth: 1)
            }
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
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
