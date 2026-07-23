import SwiftUI

struct SignupView: View {

    @State private var viewModel: SignupViewModel
    private let authApi: AuthApi
    private let sessionManager: SessionManager

    init(authApi: AuthApi, sessionManager: SessionManager) {
        self.authApi = authApi
        self.sessionManager = sessionManager
        _viewModel = State(wrappedValue: SignupViewModel(
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
                    headerSection
                        .padding(.top, 48)
                        .padding(.bottom, 36)

                    cardSection
                        .padding(.horizontal, 24)

                    footerSection
                        .padding(.top, 28)
                        .padding(.bottom, 48)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: Binding(
            get: { viewModel.registeredEmail != nil },
            set: { if !$0 { viewModel.registeredEmail = nil } }
        )) {
            EmailVerifyView(
                viewModel: EmailVerifyViewModel(
                    email: viewModel.registeredEmail ?? viewModel.email,
                    authApi: authApi
                )
            )
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("Create account")
                .font(.elsfmHero)
                .foregroundStyle(Color.elsfmText)

            Text("Join ELSFM and discover your sound.")
                .font(.elsfmCaption)
                .foregroundStyle(Color.elsfmTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
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
                    prompt: "Create a password"
                )
                FieldErrorView(key: "password", errors: viewModel.errors)
            }

            FieldErrorView(key: "general", errors: viewModel.errors)

            AuthPrimaryButton(title: "Create Account", isLoading: viewModel.isLoading) {
                viewModel.register()
            }
            .padding(.top, 4)
        }
        .padding(24)
        .background(Color.elsfmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 24, y: 8)
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack(spacing: 6) {
            Text("Already have an account?")
                .font(.elsfmCaption)
                .foregroundStyle(Color.elsfmTextSecondary)

            // NavigationLink back to previous screen (LoginView owns the stack entry)
            Button {
                // Handled by the NavigationStack pop via the back button.
                // A custom action can be wired here if the parent requires it.
            } label: {
                Text("Sign in")
                    .font(.elsfmCaption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.elsfmPrimary)
            }
        }
    }
}
