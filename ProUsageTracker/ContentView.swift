import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var store: CounterStore

    @State private var weeklyDraft = ""
    @State private var isWeeklyEditing = false
    @FocusState private var weeklyFieldIsFocused: Bool

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "M月d日EEE"
        return formatter
    }()

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(nsColor: .textBackgroundColor)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    finishWeeklyEditing()
                }

            VStack(spacing: 20) {
                HStack(alignment: .firstTextBaseline) {
                    Text("今日")
                        .font(.system(size: 24, weight: .semibold))

                    Spacer()

                    Text(Self.dateFormatter.string(from: store.currentDate))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 20) {
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
                            .font(.system(size: 17, weight: .regular))
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
                        WeeklyEditor(
                            weeklyValue: store.weekly6,
                            weeklyDraft: $weeklyDraft,
                            isEditing: $isWeeklyEditing,
                            isFocused: $weeklyFieldIsFocused,
                            onBegin: beginWeeklyEditing,
                            onFinish: finishWeeklyEditing,
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
                .frame(maxWidth: .infinity, minHeight: 72)
                .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                }

                HStack(spacing: 16) {
                    Button("今日清零") {
                        finishWeeklyEditing()
                        store.clearToday()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(SecondaryActionButtonStyle())

                    Button("本周清零") {
                        finishWeeklyEditing()
                        store.clearWeekly6()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(SecondaryActionButtonStyle())

                    Button("撤销清零") {
                        finishWeeklyEditing()
                        store.undoClear()
                    }
                    .disabled(!store.canUndoClear)
                    .frame(maxWidth: .infinity)
                    .buttonStyle(SecondaryActionButtonStyle())
                }
            }
            .frame(maxWidth: 1120)
            .padding(.horizontal, 32)
            .padding(.top, 30)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    private func beginWeeklyEditing() {
        weeklyDraft = String(store.weekly6)
        isWeeklyEditing = true
        DispatchQueue.main.async {
            weeklyFieldIsFocused = true
        }
    }

    private func finishWeeklyEditing() {
        guard isWeeklyEditing else { return }

        let trimmedDraft = weeklyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Int(trimmedDraft) {
            store.setWeekly6(max(0, value))
        }

        isWeeklyEditing = false
        weeklyFieldIsFocused = false
        weeklyDraft = String(store.weekly6)
    }

    private func cancelWeeklyEditing() {
        guard isWeeklyEditing else { return }

        isWeeklyEditing = false
        weeklyFieldIsFocused = false
        weeklyDraft = String(store.weekly6)
    }
}

private struct CounterCard<Accessory: View>: View {
    let title: String
    let dailyLabel: String
    let dailyValue: Int
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onClear: () -> Void
    let accessory: Accessory

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
        VStack(spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 23, weight: .semibold))
                    if title == "GPT-6 Pro" {
                        Text(dailyLabel)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                accessory
            }

            Spacer(minLength: 0)

            Text("\(dailyValue)")
                .font(.system(size: 74, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .frame(maxWidth: .infinity)

            Spacer(minLength: 0)

            Button("+1", action: onIncrement)
                .buttonStyle(PrimaryCounterButtonStyle())

            HStack(spacing: 16) {
                Button("-1", action: onDecrement)
                    .disabled(dailyValue == 0)
                    .frame(maxWidth: .infinity)
                    .buttonStyle(SecondaryActionButtonStyle())

                Button("清零", action: onClear)
                    .frame(maxWidth: .infinity)
                    .buttonStyle(SecondaryActionButtonStyle())
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .frame(height: 360)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct WeeklyEditor: View {
    let weeklyValue: Int
    @Binding var weeklyDraft: String
    @Binding var isEditing: Bool
    let isFocused: FocusState<Bool>.Binding
    let onBegin: () -> Void
    let onFinish: () -> Void
    let onCancel: () -> Void

    var body: some View {
        Group {
            if isEditing {
                HStack(spacing: 5) {
                    TextField("", text: $weeklyDraft)
                        .font(.system(size: 24, weight: .semibold))
                        .monospacedDigit()
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.plain)
                        .focused(isFocused)
                        .onSubmit {
                            onFinish()
                        }
                        .onExitCommand(perform: onCancel)
                    Text("次")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
            } else {
                Button(action: onBegin) {
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("本周")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(.secondary)

                        HStack(alignment: .firstTextBaseline, spacing: 5) {
                            Text("\(weeklyValue)")
                                .font(.system(size: 24, weight: .semibold))
                                .monospacedDigit()
                            Text("次")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .contentShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 128, height: 90)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        }
        .onChange(of: isFocused.wrappedValue) { focused in
            if !focused && isEditing {
                onFinish()
            }
        }
    }
}

private struct PrimaryCounterButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 22, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: 64)
            .contentShape(RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.primary)
            .background(
                Color.accentColor.opacity(configuration.isPressed ? 0.22 : 0.12),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.accentColor.opacity(0.08), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

private struct SecondaryActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .medium))
            .frame(maxWidth: .infinity, minHeight: 54)
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.primary)
            .background(
                Color(nsColor: .textBackgroundColor),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.14), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(isEnabled ? (configuration.isPressed ? 0.72 : 1) : 0.42)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}
