import Foundation

@MainActor
final class AppIdentity: ObservableObject {
    static let shared = AppIdentity()

    private let userIdKey = "balance_app_user_id"
    private let appleUserIdKey = "balance_apple_user_id"
    private let appleEmailKey = "balance_apple_email"
    private let appleFullNameKey = "balance_apple_full_name"

    @Published private(set) var appUserId: UUID
    @Published private(set) var appleUserId: String?
    @Published private(set) var appleEmail: String?
    @Published private(set) var appleFullName: String?

    var isLinkedToApple: Bool { appleUserId != nil }

    private init() {
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: userIdKey), let uuid = UUID(uuidString: raw) {
            appUserId = uuid
        } else {
            let new = UUID()
            defaults.set(new.uuidString, forKey: userIdKey)
            appUserId = new
        }
        appleUserId = defaults.string(forKey: appleUserIdKey)
        appleEmail = defaults.string(forKey: appleEmailKey)
        appleFullName = defaults.string(forKey: appleFullNameKey)
    }

    func linkAppleSignIn(userIdentifier: String, email: String?, fullName: String?) {
        let defaults = UserDefaults.standard
        defaults.set(userIdentifier, forKey: appleUserIdKey)
        defaults.set(email, forKey: appleEmailKey)
        defaults.set(fullName, forKey: appleFullNameKey)
        appleUserId = userIdentifier
        appleEmail = email
        appleFullName = fullName
        Log.app.notice("Linked Apple Sign In identity")
    }

    func unlinkAppleSignIn() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: appleUserIdKey)
        defaults.removeObject(forKey: appleEmailKey)
        defaults.removeObject(forKey: appleFullNameKey)
        appleUserId = nil
        appleEmail = nil
        appleFullName = nil
    }
}
