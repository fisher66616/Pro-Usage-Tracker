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
        GeometryReader { proxy in
            let metrics = LayoutMetrics(size: proxy.size)

            ZStack {
                canvasColor
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                VStack(spacing: metrics.outerSpacing) {
                    headerView(metrics: metrics)
                    counterCardsView(metrics: metrics)
                    summaryView(metrics: metrics)
                    actionButtonsView(metrics: metrics)
                }
                .padding(.horizontal, metrics.horizontalPadding)
                .padding(.top, metrics.topPadding)
                .padding(.bottom, metrics.bottomPadding)
                .frame(maxWidth: 1440, alignment: .top)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private func headerView(metrics: LayoutMetrics) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("今日")
                .font(.system(size: 26, weight: .semibold))

            Spacer()

            Text(Self.dateFormatter.string(from: store.currentDate))
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(height: metrics.headerHeight)
    }

    private func counterCardsView(metrics: LayoutMetrics) -> some View {
        HStack(spacing: 18) {
            CounterCard(
                title: "GPT-5.6 Pro",
                dailyLabel: "今日",
                dailyValue: store.daily56,
                metrics: metrics,
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
                metrics: metrics,
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
        .frame(maxWidth: .infinity)
        .frame(height: metrics.cardRowHeight)
    }

    private func summaryView(metrics: LayoutMetrics) -> some View {
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
        .frame(maxWidth: .infinity)
        .frame(height: metrics.summaryHeight)
        .background(surfaceColor, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.035), radius: 10, y: 3)
    }

    private func actionButtonsView(metrics: LayoutMetrics) -> some View {
        HStack(spacing: 16) {
            Button("今日清零") {
                finishWeeklyEditing()
                store.clearToday()
            }
            .buttonStyle(SecondaryActionButtonStyle(height: metrics.secondaryButtonHeight))

            Button("本周清零") {
                finishWeeklyEditing()
                store.clearWeekly6()
            }
            .buttonStyle(SecondaryActionButtonStyle(height: metrics.secondaryButtonHeight))

            Button("撤销清零") {
                cancelWeeklyEditing()
                store.undoClear()
            }
            .disabled(!store.canUndoClear)
            .buttonStyle(SecondaryActionButtonStyle(height: metrics.secondaryButtonHeight))
        }
        .frame(maxWidth: .infinity)
        .frame(height: metrics.secondaryButtonHeight)
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
    let metrics: LayoutMetrics
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
        metrics: LayoutMetrics,
        onIncrement: @escaping () -> Void,
        onDecrement: @escaping () -> Void,
        onClear: @escaping () -> Void,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.title = title
        self.dailyLabel = dailyLabel
        self.dailyValue = dailyValue
        self.metrics = metrics
        self.onIncrement = onIncrement
        self.onDecrement = onDecrement
        self.onClear = onClear
        self.accessory = accessory()
    }

    var body: some View {
        VStack(spacing: metrics.cardSpacing) {
            cardHeader
            countView
            incrementButton
            decrementRow
        }
        .padding(metrics.cardPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(surfaceColor, in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.035), radius: 10, y: 3)
    }

    private var cardHeader: some View {
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
        .frame(maxWidth: .infinity)
        .frame(height: metrics.cardHeaderHeight, alignment: .top)
    }

    private var countView: some View {
        Text("\(dailyValue)")
            .font(.system(size: 78, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var incrementButton: some View {
        Button("+1", action: onIncrement)
            .buttonStyle(PrimaryCounterButtonStyle(height: metrics.primaryButtonHeight))
    }

    private var decrementRow: some View {
        HStack(spacing: 16) {
            Button("-1", action: onDecrement)
                .disabled(dailyValue == 0)
                .buttonStyle(SecondaryActionButtonStyle(height: metrics.secondaryButtonHeight))

            Button("清零", action: onClear)
                .buttonStyle(SecondaryActionButtonStyle(height: metrics.secondaryButtonHeight))
        }
        .frame(maxWidth: .infinity)
        .frame(height: metrics.secondaryButtonHeight)
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

    @State private var isHovering = false

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
        .frame(width: 88, height: 44)
    }

    private var normalButton: some View {
        Button(action: onBegin) {
            Text("\(weeklyValue)")
                .font(.system(size: 22, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(width: 88, height: 44)
                .contentShape(RoundedRectangle(cornerRadius: 12))
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(surfaceColor)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.accentColor.opacity(isHovering ? 0.04 : 0))
                        }
                }
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(isHovering ? 0.14 : 0.08), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .accessibilityLabel("GPT-6 Pro 本周次数")
        .accessibilityValue(Text("\(weeklyValue)"))
    }

    private var editingContent: some View {
        HStack(spacing: 4) {
            TextField("", text: $weeklyDraft)
                .font(.system(size: 18, weight: .semibold))
                .monospacedDigit()
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .frame(width: 48, height: 28)
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
                .accessibilityLabel("GPT-6 Pro 本周次数")

            Button(action: onCommit) {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .accessibilityLabel("保存本周次数")
        }
        .frame(width: 88, height: 44)
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .background(surfaceColor, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct LayoutMetrics {
    let isCompact: Bool
    let outerSpacing: CGFloat
    let horizontalPadding: CGFloat
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let headerHeight: CGFloat
    let cardPadding: CGFloat
    let cardSpacing: CGFloat
    let cardHeaderHeight: CGFloat
    let primaryButtonHeight: CGFloat
    let secondaryButtonHeight: CGFloat
    let summaryHeight: CGFloat
    let cardRowHeight: CGFloat

    init(size: CGSize) {
        isCompact = size.height < 580
        let transitionProgress = min(max((size.height - 570) / 10, 0), 1)
        outerSpacing = Self.interpolate(12, 18, progress: transitionProgress)
        horizontalPadding = size.width < 900 ? 24 : 30
        topPadding = Self.interpolate(16, 22, progress: transitionProgress)
        bottomPadding = Self.interpolate(16, 24, progress: transitionProgress)
        headerHeight = 34
        cardPadding = Self.interpolate(18, 23, progress: transitionProgress)
        cardSpacing = Self.interpolate(6, 8, progress: transitionProgress)
        cardHeaderHeight = 56
        primaryButtonHeight = Self.interpolate(56, 60, progress: transitionProgress)
        secondaryButtonHeight = Self.interpolate(44, 50, progress: transitionProgress)
        summaryHeight = Self.interpolate(56, 66, progress: transitionProgress)

        let minimumCardHeight: CGFloat = isCompact ? 320 : 330
        let maximumCardHeight: CGFloat = isCompact ? 330 : 480
        let availableCardHeight = max(
            0,
            size.height
                - topPadding
                - bottomPadding
                - headerHeight
                - summaryHeight
                - secondaryButtonHeight
                - outerSpacing * 3
        )
        cardRowHeight = min(
            max(availableCardHeight, minimumCardHeight),
            maximumCardHeight
        )
    }

    private static func interpolate(_ compact: CGFloat, _ regular: CGFloat, progress: CGFloat) -> CGFloat {
        compact + (regular - compact) * progress
    }
}

private struct PrimaryCounterButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    let height: CGFloat

    init(height: CGFloat = 60) {
        self.height = height
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 22, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
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
    let height: CGFloat

    init(height: CGFloat = 50) {
        self.height = height
    }

    private var surfaceColor: Color {
        colorScheme == .dark
            ? Color(nsColor: .controlBackgroundColor)
            : Color(nsColor: .textBackgroundColor)
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .medium))
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
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
