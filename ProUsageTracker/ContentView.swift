import SwiftUI

struct ContentView: View {
    @ObservedObject var store: CounterStore

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "M月d日EEE"
        return formatter
    }()

    private var weeklyBinding: Binding<Int> {
        Binding(
            get: { store.weekly6 },
            set: { store.setWeekly6($0) }
        )
    }

    var body: some View {
        VStack(spacing: 28) {
            HStack(alignment: .firstTextBaseline) {
                Text("今日")
                    .font(.system(size: 38, weight: .semibold))

                Spacer()

                Text(Self.dateFormatter.string(from: store.currentDate))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 24) {
                CounterCard(
                    title: "GPT-5.6 Pro",
                    dailyLabel: "今日",
                    dailyValue: store.daily56,
                    onIncrement: store.incrementDaily56,
                    onDecrement: store.decrementDaily56,
                    onClear: store.clearDaily56
                )

                CounterCard(
                    title: "GPT-6 Pro",
                    dailyLabel: "今日",
                    dailyValue: store.daily6,
                    weeklyBinding: weeklyBinding,
                    onIncrement: store.incrementDaily6,
                    onDecrement: store.decrementDaily6,
                    onClear: store.clearDaily6
                )
            }

            HStack {
                Text("今日合计")
                    .font(.system(size: 18, weight: .medium))

                Spacer()

                Text("\(store.dailyTotal) 次")
                    .font(.system(size: 22, weight: .semibold))
                    .monospacedDigit()
            }
            .padding(.horizontal, 4)

            HStack(spacing: 14) {
                Button("今日清零", action: store.clearToday)
                    .frame(maxWidth: .infinity)
                Button("本周清零", action: store.clearWeekly6)
                    .frame(maxWidth: .infinity)
                Button("撤销清零", action: store.undoClear)
                    .disabled(!store.canUndoClear)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(36)
    }
}

private struct CounterCard: View {
    let title: String
    let dailyLabel: String
    let dailyValue: Int
    let weeklyBinding: Binding<Int>?
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onClear: () -> Void

    init(
        title: String,
        dailyLabel: String,
        dailyValue: Int,
        weeklyBinding: Binding<Int>? = nil,
        onIncrement: @escaping () -> Void,
        onDecrement: @escaping () -> Void,
        onClear: @escaping () -> Void
    ) {
        self.title = title
        self.dailyLabel = dailyLabel
        self.dailyValue = dailyValue
        self.weeklyBinding = weeklyBinding
        self.onIncrement = onIncrement
        self.onDecrement = onDecrement
        self.onClear = onClear
    }

    var body: some View {
        VStack(spacing: 22) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 21, weight: .semibold))
                    if weeklyBinding != nil {
                        Text(dailyLabel)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let weeklyBinding {
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("本周")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 5) {
                            TextField("", value: weeklyBinding, formatter: Self.numberFormatter)
                                .textFieldStyle(.roundedBorder)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 78)
                                .monospacedDigit()
                            Text("次")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text(dailyLabel)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            Text("\(dailyValue)")
                .font(.system(size: 72, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .frame(maxWidth: .infinity)

            Spacer(minLength: 8)

            Button(action: onIncrement) {
                Text("+1")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .frame(height: 56)
            .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 12) {
                Button("-1", action: onDecrement)
                    .disabled(dailyValue == 0)
                    .frame(maxWidth: .infinity)
                Button("清零", action: onClear)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
        }
        .padding(28)
        .frame(maxWidth: .infinity, minHeight: 360)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }

    private static var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.allowsFloats = false
        return formatter
    }
}
