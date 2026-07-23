import SwiftUI

// MARK: - LoginView

struct LoginView: View {

    @State private var viewModel: LoginViewModel
    private let authApi: AuthApi
    private let sessionManager: SessionManager

    init(authApi: AuthApi, sessionManager: SessionManager) {
        self.authApi = authApi
        self.sessionManager = sessionManager
        _viewModel = State(wrappedValue: LoginViewModel(
            authApi: authApi,
            sessionManager: sessionManager
        ))
    }

    var body: some View {
        ZStack {
            Color.elsfmBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    logoSection
                        .padding(.top, 64)
                        .padding(.bottom, 44)

                    cardSection
                        .padding(.horizontal, 24)

                    footerSection
                        .padding(.top, 28)
                        .padding(.bottom, 48)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Logo

    private var logoSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.elsfmPrimary.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: "music.quarternote.3")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(Color.elsfmPrimary)
            }

            Text("ELSFM")
                .font(.elsfmHero)
                .foregroundStyle(Color.elsfmText)
                .kerning(3)

            Text("Your music, everywhere.")
                .font(.elsfmCaption)
                .foregroundStyle(Color.elsfmTextSecondary)
        }
    }

    // MARK: - Card

    private var cardSection: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                AuthTextField(
                    label: "Email",
                    text: $viewModel.email,
                    prompt: "you@example.com",
                    keyboardType: .emailAddress
                )
                FieldErrorView(key: "email", errors: viewModel.errors)
            }

            VStack(alignment: .leading, spacing: 6) {
                AuthSecureField(
                    label: "Password",
                    text: $viewModel.password,
                    prompt: "Your password"
                )
                FieldErrorView(key: "password", errors: viewModel.errors)
            }

            FieldErrorView(key: "general", errors: viewModel.errors)

            AuthPrimaryButton(title: "Sign In", isLoading: viewModel.isLoading) {
                viewModel.login()
            }
            .padding(.top, 4)

            authDivider

            GoogleSignInButton(isLoading: viewModel.googleSignInLoading) {
                viewModel.loginWithGoogle()
            }

            HStack {
                Spacer()
                NavigationLink {
                    PasswordResetView(authApi: authApi, sessionManager: sessionManager)
                } label: {
                    Text("Forgot password?")
                        .font(.elsfmCaption)
                        .foregroundStyle(Color.elsfmTextSecondary)
                        .underline()
                }
            }
        }
        .padding(24)
        .background(Color.elsfmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 24, y: 8)
    }

    private var authDivider: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.elsfmDivider)
                .frame(height: 1)
            Text("or")
                .font(.elsfmCaption)
                .foregroundStyle(Color.elsfmTextSecondary)
                .padding(.horizontal, 14)
            Rectangle()
                .fill(Color.elsfmDivider)
                .frame(height: 1)
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack(spacing: 6) {
            Text("Don't have an account?")
                .font(.elsfmCaption)
                .foregroundStyle(Color.elsfmTextSecondary)

            NavigationLink {
                SignupView(authApi: authApi, sessionManager: sessionManager)
            } label: {
                Text("Sign up")
                    .font(.elsfmCaption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.elsfmPrimary)
            }
        }
    }
}

// MARK: - Shared Auth UI Components
// Internal access — available to all Auth feature files in the same module.

struct AuthTextField: View {
    let label: String
    @Binding var text: String
    let prompt: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.elsfmLabel)
                .foregroundStyle(Color.elsfmTextSecondary)

            TextField(prompt, text: $text)
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(.elsfmBody)
                .foregroundStyle(Color.elsfmText)
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(Color.elsfmBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.elsfmDivider, lineWidth: 1)
                )
        }
    }
}

struct AuthSecureField: View {
    let label: String
    @Binding var text: String
    let prompt: String
    @State private var isRevealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.elsfmLabel)
                .foregroundStyle(Color.elsfmTextSecondary)

            HStack {
                Group {
                    if isRevealed {
                        TextField(prompt, text: $text)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        SecureField(prompt, text: $text)
                    }
                }
                .font(.elsfmBody)
                .foregroundStyle(Color.elsfmText)

                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .foregroundStyle(Color.elsfmTextSecondary)
                        .imageScale(.medium)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Color.elsfmBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.elsfmDivider, lineWidth: 1)
            )
        }
    }
}

struct AuthPrimaryButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color.elsfmOnPrimary)
                } else {
                    Text(title)
                        .font(.elsfmBody)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.elsfmOnPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .background(Color.elsfmPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .disabled(isLoading)
        .opacity(isLoading ? 0.8 : 1)
        .animation(.easeInOut(duration: 0.15), value: isLoading)
    }
}

struct GoogleSignInButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color.elsfmText)
                } else {
                    Image(systemName: "globe")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.elsfmText)

                    Text("Continue with Google")
                        .font(.elsfmBody)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.elsfmText)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .background(Color.elsfmBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.elsfmDivider, lineWidth: 1)
        )
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1)
    }
}

struct FieldErrorView: View {
    let key: String
    let errors: [String: [String]]

    var body: some View {
        if let messages = errors[key], let first = messages.first {
            Text(first)
                .font(.elsfmLabel)
                .foregroundStyle(Color.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}
