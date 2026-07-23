import SwiftUI

struct PasswordResetView: View {

    @State private var viewModel: PasswordResetViewModel
    @Environment(\.dismiss) private var dismiss

    init(authApi: AuthApi, sessionManager _: SessionManager) {
        _viewModel = State(wrappedValue: PasswordResetViewModel(authApi: authApi))
    }

    var body: some View {
        ZStack {
            Color.elsfmBackground
                .ignoresSafeArea()

            if viewModel.resetComplete {
                successState
            } else {
                phaseContent
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Reset Password")
        .animation(.easeInOut(duration: 0.25), value: viewModel.phase)
        .animation(.easeInOut(duration: 0.25), value: viewModel.resetComplete)
    }

    // MARK: - Phase Content

    @ViewBuilder
    private var phaseContent: some View {
        switch viewModel.phase {
        case .request:
            requestPhase
        case .complete:
            completePhase
        }
    }

    // MARK: - Phase 1: Request

    private var requestPhase: some View {
        ScrollView {
            VStack(spacing: 0) {
                requestHeader
                    .padding(.top, 48)
                    .padding(.bottom, 36)

                requestCard
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    private var requestHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.elsfmPrimary.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: "lock.open.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Color.elsfmPrimary)
            }

            Text("Forgot your password?")
                .font(.elsfmTitle)
                .foregroundStyle(Color.elsfmText)

            Text("Enter your email and we'll send you\na link to reset your password.")
                .font(.elsfmCaption)
                .foregroundStyle(Color.elsfmTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }

    private var requestCard: some View {
        VStack(spacing: 18) {
            AuthTextField(
                label: "Email",
                text: $viewModel.email,
                prompt: "you@example.com",
                keyboardType: .emailAddress
            )

            if let errorMessage = viewModel.error {
                Text(errorMessage)
                    .font(.elsfmLabel)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            AuthPrimaryButton(title: "Send Reset Email", isLoading: viewModel.isLoading) {
                viewModel.requestReset()
            }
            .padding(.top, 4)
        }
        .padding(24)
        .background(Color.elsfmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 24, y: 8)
    }

    // MARK: - Phase 2: Complete

    private var completePhase: some View {
        ScrollView {
            VStack(spacing: 0) {
                completeHeader
                    .padding(.top, 48)
                    .padding(.bottom, 36)

                completeCard
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    private var completeHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.elsfmPrimary.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: "envelope.open.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Color.elsfmPrimary)
            }

            Text("Check your email")
                .font(.elsfmTitle)
                .foregroundStyle(Color.elsfmText)

            Text("Enter the reset token we sent to\n**\(viewModel.email)**")
                .font(.elsfmCaption)
                .foregroundStyle(Color.elsfmTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }

    private var completeCard: some View {
        VStack(spacing: 18) {
            AuthTextField(
                label: "Reset Token",
                text: $viewModel.token,
                prompt: "Paste the token from your email"
            )

            AuthSecureField(
                label: "New Password",
                text: $viewModel.newPassword,
                prompt: "Choose a new password"
            )

            if let errorMessage = viewModel.error {
                Text(errorMessage)
                    .font(.elsfmLabel)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            AuthPrimaryButton(title: "Reset Password", isLoading: viewModel.isLoading) {
                viewModel.completeReset()
            }
            .padding(.top, 4)
        }
        .padding(24)
        .background(Color.elsfmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 24, y: 8)
    }

    // MARK: - Success State

    private var successState: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 96, height: 96)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.green)
            }

            VStack(spacing: 10) {
                Text("Password reset!")
                    .font(.elsfmHero)
                    .foregroundStyle(Color.elsfmText)

                Text("Your password has been updated.\nSign in with your new credentials.")
                    .font(.elsfmCaption)
                    .foregroundStyle(Color.elsfmTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            AuthPrimaryButton(title: "Back to Sign In", isLoading: false) {
                dismiss()
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}
