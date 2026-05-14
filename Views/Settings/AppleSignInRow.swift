import SwiftUI
import AuthenticationServices

struct AppleSignInRow: View {
    @ObservedObject var identity: AppIdentity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if identity.isLinkedToApple {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(Theme.Colors.income)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Linked with Apple")
                            .font(.system(size: 15, weight: .semibold))
                        if let email = identity.appleEmail, !email.isEmpty {
                            Text(email)
                                .font(.system(size: 12))
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                        }
                    }
                    Spacer()
                    Button("Unlink") { identity.unlinkAppleSignIn() }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.Colors.expense)
                }
            } else {
                Text("Linking with Apple lets you keep your Balance Plus subscription and identity across reinstall and new devices. Your finance data still lives in iCloud — Apple only gives us an anonymous identifier.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.email, .fullName]
                } onCompletion: { result in
                    handle(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 44)
                .cornerRadius(12)
                .accessibilityLabel("Sign in with Apple")
            }
        }
    }

    private func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let cred = auth.credential as? ASAuthorizationAppleIDCredential {
                let name = [cred.fullName?.givenName, cred.fullName?.familyName].compactMap { $0 }.joined(separator: " ")
                identity.linkAppleSignIn(userIdentifier: cred.user,
                                         email: cred.email,
                                         fullName: name.isEmpty ? nil : name)
                Haptics.success()
            }
        case .failure(let err):
            Log.app.warning("Sign in with Apple failed: \(err.localizedDescription, privacy: .public)")
        }
    }
}
