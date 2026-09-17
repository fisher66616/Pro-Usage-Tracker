import Combine
import Foundation

@MainActor
final class CounterStore: ObservableObject {
    @Published private(set) var daily56: Int
    @Published private(set) var daily6: Int
    @Published private(set) var weekly6: Int
    @Published private(set) var currentDate: Date
    @Published private(set) var canUndoClear = false

    private struct Snapshot {
        let daily56: Int
        let daily6: Int
        let weekly6: Int
    }

    private enum Key {
        static let daily56 = "daily56"
        static let daily6 = "daily6"
        static let weekly6 = "weekly6"
        static let lastActivityDate = "lastActivityDate"
    }

    private let defaults = UserDefaults.standard
    private var lastActivityDate: Date
    private var undoSnapshot: Snapshot?

    var dailyTotal: Int {
        daily56 + daily6
    }

    init() {
        let now = Date()
        daily56 = max(0, defaults.integer(forKey: Key.daily56))
        daily6 = max(0, defaults.integer(forKey: Key.daily6))
        weekly6 = max(0, defaults.integer(forKey: Key.weekly6))
        currentDate = now
        if let timestamp = defaults.object(forKey: Key.lastActivityDate) as? TimeInterval {
            lastActivityDate = Date(timeIntervalSince1970: timestamp)
        } else {
            lastActivityDate = now
        }

        refreshDayIfNeeded()
    }

    func refreshDayIfNeeded() {
        let now = Date()
        let calendar = Calendar.autoupdatingCurrent

        guard !calendar.isDate(lastActivityDate, inSameDayAs: now) else {
            currentDate = now
            return
        }

        // A natural-day change resets only today's counters and invalidates undo.
        daily56 = 0
        daily6 = 0
        undoSnapshot = nil
        canUndoClear = false
        currentDate = now
        lastActivityDate = now
        persist()
    }

    func incrementDaily56() {
        refreshDayIfNeeded()
        invalidateUndo()
        daily56 += 1
        touchAndPersist()
    }

    func decrementDaily56() {
        refreshDayIfNeeded()
        guard daily56 > 0 else { return }
        invalidateUndo()
        daily56 -= 1
        touchAndPersist()
    }

    func incrementDaily6() {
        refreshDayIfNeeded()
        invalidateUndo()
        daily6 += 1
        weekly6 += 1
        touchAndPersist()
    }

    func decrementDaily6() {
        refreshDayIfNeeded()
        guard daily6 > 0 else { return }
        invalidateUndo()
        daily6 -= 1
        if weekly6 > 0 {
            weekly6 -= 1
        }
        touchAndPersist()
    }

    func setWeekly6(_ value: Int) {
        refreshDayIfNeeded()
        invalidateUndo()
        weekly6 = max(0, value)
        touchAndPersist()
    }

    func clearDaily56() {
        performClear { daily56 = 0 }
    }

    func clearDaily6() {
        performClear { daily6 = 0 }
    }

    func clearToday() {
        performClear {
            daily56 = 0
            daily6 = 0
        }
    }

    func clearWeekly6() {
        performClear { weekly6 = 0 }
    }

    func undoClear() {
        refreshDayIfNeeded()
        guard let snapshot = undoSnapshot else { return }

        daily56 = snapshot.daily56
        daily6 = snapshot.daily6
        weekly6 = snapshot.weekly6
        undoSnapshot = nil
        canUndoClear = false
        touchAndPersist()
    }

    private func performClear(_ mutation: () -> Void) {
        refreshDayIfNeeded()
        let before = Snapshot(daily56: daily56, daily6: daily6, weekly6: weekly6)
        mutation()

        guard before.daily56 != daily56 || before.daily6 != daily6 || before.weekly6 != weekly6 else {
            return
        }

        undoSnapshot = before
        canUndoClear = true
        touchAndPersist()
    }

    private func invalidateUndo() {
        undoSnapshot = nil
        canUndoClear = false
    }

    private func touchAndPersist() {
        let now = Date()
        currentDate = now
        lastActivityDate = now
        persist()
    }

    private func persist() {
        defaults.set(daily56, forKey: Key.daily56)
        defaults.set(daily6, forKey: Key.daily6)
        defaults.set(weekly6, forKey: Key.weekly6)
        defaults.set(lastActivityDate.timeIntervalSince1970, forKey: Key.lastActivityDate)
    }
}
