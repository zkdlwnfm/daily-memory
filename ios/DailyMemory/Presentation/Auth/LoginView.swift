import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var showSignUp = false
    @State private var showResetPassword = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo & Welcome
                    VStack(spacing: 12) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 72))
                            .foregroundColor(.accentColor)

                        Text("Engram")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Your personal AI memory companion")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)

                    // Email/Password Form
                    VStack(spacing: 16) {
                        TextField("Email", text: $viewModel.email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)

                        SecureField("Password", text: $viewModel.password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.password)

                        // Login Button
                        Button {
                            Task { await viewModel.signIn() }
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!viewModel.isEmailValid || viewModel.isLoading)

                        // Forgot Password
                        Button {
                            showResetPassword = true
                        } label: {
                            Text("Forgot Password?")
                                .font(.footnote)
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.horizontal)

                    // Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.secondary.opacity(0.3))
                        Text("or")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.secondary.opacity(0.3))
                    }
                    .padding(.horizontal)

                    // Social Sign-In
                    VStack(spacing: 12) {
                        // Apple Sign-In
                        SignInWithAppleButton(.signIn) { request in
                            let hashedNonce = viewModel.prepareAppleSignIn()
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = hashedNonce
                        } onCompletion: { result in
                            Task { await viewModel.handleAppleSignIn(result: result) }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .cornerRadius(12)

                        // Google Sign-In
                        Button {
                            Task { await viewModel.signInWithGoogle() }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "globe")
                                    .font(.title3)
                                Text("Sign in with Google")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .foregroundColor(.primary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)

                    // Sign Up Link
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.secondary)
                        Button("Sign Up") {
                            showSignUp = true
                        }
                        .fontWeight(.semibold)
                    }
                    .font(.footnote)

                    // Skip (use without account)
                    Button {
                        viewModel.skipSignIn()
                    } label: {
                        Text("Continue without account")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .underline()
                    }
                    .padding(.bottom, 32)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showResetPassword) {
                ResetPasswordView()
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var error: String?

    private let authService = AuthService.shared

    var isEmailValid: Bool {
        !email.isEmpty && email.contains("@") && !password.isEmpty
    }

    func signIn() async {
        isLoading = true
        let result = await authService.signIn(email: email, password: password)
        isLoading = false

        if case .failure(let authError) = result {
            error = authError.errorDescription
        }
    }

    func prepareAppleSignIn() -> String {
        authService.prepareAppleSignIn()
    }

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        let authResult = await authService.handleAppleSignIn(result: result)
        isLoading = false

        if case .failure(let authError) = authResult {
            error = authError.errorDescription
        }
    }

    func signInWithGoogle() async {
        isLoading = true
        let result = await authService.signInWithGoogle()
        isLoading = false

        if case .failure(let authError) = result {
            error = authError.errorDescription
        }
    }

    func skipSignIn() {
        // Allow use without sign-in - data stays local only
        UserDefaults.standard.set(true, forKey: "skippedSignIn")
        // Post notification for ContentView to handle
        NotificationCenter.default.post(name: .skipSignIn, object: nil)
    }
}

extension Notification.Name {
    static let skipSignIn = Notification.Name("skipSignIn")
}

// MARK: - Sign Up View

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SignUpViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Start preserving your memories")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 32)

                    VStack(spacing: 16) {
                        TextField("Name", text: $viewModel.displayName)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.name)

                        TextField("Email", text: $viewModel.email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)

                        SecureField("Password (6+ characters)", text: $viewModel.password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)

                        SecureField("Confirm Password", text: $viewModel.confirmPassword)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)

                        if viewModel.password != viewModel.confirmPassword && !viewModel.confirmPassword.isEmpty {
                            Text("Passwords don't match")
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        Button {
                            Task {
                                await viewModel.signUp()
                                if viewModel.success { dismiss() }
                            }
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Create Account")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!viewModel.isValid || viewModel.isLoading)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
    }
}

@MainActor
class SignUpViewModel: ObservableObject {
    @Published var displayName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var error: String?
    @Published var success = false

    private let authService = AuthService.shared

    var isValid: Bool {
        !email.isEmpty && email.contains("@") &&
        password.count >= 6 &&
        password == confirmPassword
    }

    func signUp() async {
        isLoading = true
        let result = await authService.signUp(
            email: email,
            password: password,
            displayName: displayName.isEmpty ? nil : displayName
        )
        isLoading = false

        switch result {
        case .success:
            success = true
        case .failure(let authError):
            error = authError.errorDescription
        }
    }
}

// MARK: - Reset Password View

struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var sent = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)

                    Text("Reset Password")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Enter your email and we'll send you a reset link")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                if sent {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)

                        Text("Email Sent!")
                            .font(.headline)

                        Text("Check your inbox for the reset link")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Button("Done") { dismiss() }
                            .padding(.top)
                    }
                } else {
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)

                        Button {
                            Task {
                                isLoading = true
                                let result = await AuthService.shared.sendPasswordReset(to: email)
                                isLoading = false
                                switch result {
                                case .success:
                                    sent = true
                                case .failure(let authError):
                                    error = authError.errorDescription
                                }
                            }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Send Reset Link")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(email.isEmpty || !email.contains("@") || isLoading)
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") { error = nil }
            } message: {
                Text(error ?? "")
            }
        }
    }
}

#Preview {
    LoginView()
}
