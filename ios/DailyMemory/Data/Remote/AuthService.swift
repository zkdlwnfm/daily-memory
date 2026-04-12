import Foundation
import FirebaseAuth
import FirebaseMessaging
import AuthenticationServices
import CryptoKit

/// User profile model
struct UserProfile: Codable, Equatable {
    let uid: String
    var email: String?
    var displayName: String?
    var photoURL: String?
    var isPremium: Bool
    var createdAt: Date
    var lastLoginAt: Date

    init(
        uid: String,
        email: String? = nil,
        displayName: String? = nil,
        photoURL: String? = nil,
        isPremium: Bool = false,
        createdAt: Date = Date(),
        lastLoginAt: Date = Date()
    ) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.isPremium = isPremium
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
    }

    static func from(firebaseUser user: User) -> UserProfile {
        UserProfile(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
            photoURL: user.photoURL?.absoluteString,
            isPremium: false,
            createdAt: user.metadata.creationDate ?? Date(),
            lastLoginAt: user.metadata.lastSignInDate ?? Date()
        )
    }
}

/// Authentication state
enum AuthState: Equatable {
    case unknown
    case signedOut
    case signedIn(UserProfile)
}

/// Authentication errors
enum AuthError: LocalizedError {
    case signInFailed(String)
    case signUpFailed(String)
    case signOutFailed(String)
    case appleSignInFailed
    case googleSignInFailed
    case passwordResetFailed(String)
    case deleteAccountFailed(String)
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .signInFailed(let msg): return "Sign in failed: \(msg)"
        case .signUpFailed(let msg): return "Sign up failed: \(msg)"
        case .signOutFailed(let msg): return "Sign out failed: \(msg)"
        case .appleSignInFailed: return "Apple Sign-In failed"
        case .googleSignInFailed: return "Google Sign-In failed"
        case .passwordResetFailed(let msg): return "Password reset failed: \(msg)"
        case .deleteAccountFailed(let msg): return "Delete account failed: \(msg)"
        case .notSignedIn: return "Not signed in"
        }
    }
}

/// Firebase Authentication service
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var authState: AuthState = .unknown
    @Published private(set) var isLoading = false

    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?

    var currentUser: UserProfile? {
        if case .signedIn(let profile) = authState {
            return profile
        }
        return nil
    }

    var isSignedIn: Bool {
        currentUser != nil
    }

    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    private init() {
        setupAuthStateListener()
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    // MARK: - Auth State Listener

    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    self?.authState = .signedIn(.from(firebaseUser: user))
                    // Subscribe to FCM user topic for push notifications
                    self?.subscribeToFCMTopic(uid: user.uid)
                } else {
                    self?.authState = .signedOut
                }
            }
        }
    }

    private func subscribeToFCMTopic(uid: String) {
        let topic = "user_\(uid)"
        Messaging.messaging().subscribe(toTopic: topic) { error in
            if let error = error {
            } else {
            }
        }
    }

    // MARK: - Email/Password Auth

    func signIn(email: String, password: String) async -> Result<UserProfile, AuthError> {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let profile = UserProfile.from(firebaseUser: result.user)
            authState = .signedIn(profile)
            return .success(profile)
        } catch {
            return .failure(.signInFailed(error.localizedDescription))
        }
    }

    func signUp(email: String, password: String, displayName: String?) async -> Result<UserProfile, AuthError> {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)

            // Update display name if provided
            if let displayName = displayName {
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try await changeRequest.commitChanges()
            }

            let profile = UserProfile.from(firebaseUser: result.user)
            authState = .signedIn(profile)
            return .success(profile)
        } catch {
            return .failure(.signUpFailed(error.localizedDescription))
        }
    }

    // MARK: - Apple Sign-In

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async -> Result<UserProfile, AuthError> {
        isLoading = true
        defer { isLoading = false }

        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = appleIDCredential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8),
                  let nonce = currentNonce else {
                return .failure(.appleSignInFailed)
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken: tokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )

            do {
                let authResult = try await Auth.auth().signIn(with: credential)
                let profile = UserProfile.from(firebaseUser: authResult.user)
                authState = .signedIn(profile)
                return .success(profile)
            } catch {
                return .failure(.signInFailed(error.localizedDescription))
            }

        case .failure:
            return .failure(.appleSignInFailed)
        }
    }

    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async -> Result<UserProfile, AuthError> {
        isLoading = true
        defer { isLoading = false }

        // Google Sign-In requires GIDSignIn configuration
        // This would be configured with the GoogleService-Info.plist CLIENT_ID
        // For now, return an error indicating configuration is needed
        return .failure(.googleSignInFailed)
    }

    // MARK: - Sign Out

    func signOut() -> Result<Void, AuthError> {
        do {
            try Auth.auth().signOut()
            authState = .signedOut
            return .success(())
        } catch {
            return .failure(.signOutFailed(error.localizedDescription))
        }
    }

    // MARK: - Password Reset

    func sendPasswordReset(to email: String) async -> Result<Void, AuthError> {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            return .success(())
        } catch {
            return .failure(.passwordResetFailed(error.localizedDescription))
        }
    }

    // MARK: - Update Profile

    func updateDisplayName(_ name: String) async -> Result<Void, AuthError> {
        guard let user = Auth.auth().currentUser else {
            return .failure(.notSignedIn)
        }

        do {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()

            // Update local state
            if case .signedIn(var profile) = authState {
                profile.displayName = name
                authState = .signedIn(profile)
            }

            return .success(())
        } catch {
            return .failure(.signInFailed(error.localizedDescription))
        }
    }

    // MARK: - Delete Account

    func deleteAccount() async -> Result<Void, AuthError> {
        guard let user = Auth.auth().currentUser else {
            return .failure(.notSignedIn)
        }

        do {
            try await user.delete()
            authState = .signedOut
            return .success(())
        } catch {
            return .failure(.deleteAccountFailed(error.localizedDescription))
        }
    }

    // MARK: - Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
