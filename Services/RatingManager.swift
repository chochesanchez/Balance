import Foundation
import StoreKit
import UIKit

@MainActor
final class RatingManager: ObservableObject {
    static let shared = RatingManager()

    enum Event: String {
        case recordedTransaction
        case createdFirstGoal
        case completedGoal
        case usedAppDailyMilestone
        case successfullyRestored
    }

    private let positiveCountKey = "balance_rating_positive_count"
    private let lastRequestKey   = "balance_rating_last_request"
    private let usageDatesKey    = "balance_rating_usage_dates"
    private let suppressKey      = "balance_rating_suppressed"

    private let cooldown: TimeInterval = 60 * 60 * 24 * 90

    @Published private(set) var positiveCount: Int
    @Published private(set) var lastRequest: Date?
    private(set) var distinctUsageDays: Int

    private init() {
        let defaults = UserDefaults.standard
        positiveCount = defaults.integer(forKey: positiveCountKey)
        lastRequest = defaults.object(forKey: lastRequestKey) as? Date
        let raw = (defaults.array(forKey: usageDatesKey) as? [TimeInterval]) ?? []
        distinctUsageDays = raw.count
    }

    func registerAppForegrounded(now: Date = Date()) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now).timeIntervalSinceReferenceDate
        var raw = (UserDefaults.standard.array(forKey: usageDatesKey) as? [TimeInterval]) ?? []
        if !raw.contains(today) {
            raw.append(today)
            UserDefaults.standard.set(raw, forKey: usageDatesKey)
            distinctUsageDays = raw.count
            if distinctUsageDays == 5 || distinctUsageDays == 14 {
                registerPositiveEvent(.usedAppDailyMilestone)
            }
        }
    }

    func registerPositiveEvent(_ event: Event) {
        guard !UserDefaults.standard.bool(forKey: suppressKey) else { return }
        positiveCount += 1
        UserDefaults.standard.set(positiveCount, forKey: positiveCountKey)
        Log.app.debug("Rating positive event: \(event.rawValue, privacy: .public) total=\(self.positiveCount)")
        maybePrompt(reason: event)
    }

    func suppress(_ suppressed: Bool) {
        UserDefaults.standard.set(suppressed, forKey: suppressKey)
    }

    func canPromptNow(now: Date = Date()) -> Bool {
        if UserDefaults.standard.bool(forKey: suppressKey) { return false }
        if positiveCount < 3 { return false }
        if let last = lastRequest, now.timeIntervalSince(last) < cooldown { return false }
        return true
    }

    private func maybePrompt(reason: Event) {
        guard canPromptNow() else { return }
        guard let scene = activeScene() else { return }
        SKStoreReviewController.requestReview(in: scene)
        let now = Date()
        UserDefaults.standard.set(now, forKey: lastRequestKey)
        lastRequest = now
        Log.app.notice("Requested SKStoreReviewController review prompt (reason: \(reason.rawValue, privacy: .public))")
    }

    private func activeScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }

    #if DEBUG
    func debugResetAndPromptNow() {
        positiveCount = 99
        UserDefaults.standard.set(positiveCount, forKey: positiveCountKey)
        UserDefaults.standard.removeObject(forKey: lastRequestKey)
        lastRequest = nil
        maybePrompt(reason: .usedAppDailyMilestone)
    }
    #endif
}
