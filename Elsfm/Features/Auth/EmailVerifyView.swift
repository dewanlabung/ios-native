import SwiftUI

struct EmailVerifyView: View {

    @State var viewModel: EmailVerifyViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: EmailVerifyViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.elsfmBackground
                .ignoresSafeArea()

            if viewModel.isVerified {
                successState
            } else {
                verifyContent
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Verify Email")
        .animation(.easeInOut(duration: 0.25), value: viewModel.isVerified)
    }

    // MARK: - Verify Content

    private var verifyContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                iconSection
                    .padding(.top, 48)
                    .padding(.bottom, 32)

                cardSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
    }

    private var iconSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.elsfmPrimary.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: "envelope.badge")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(Color.elsfmPrimary)
            }

            Text("Check your inbox")
                .font(.elsfmTitle)
                .foregroundStyle(Color.elsfmText)

            Text("We sent a 6-digit code to\n**\(viewModel.email)**")
                .font(.elsfmCaption)
                .foregroundStyle(Color.elsfmTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }

    private var cardSection: some View {
        VStack(spacing: 24) {
            OTPField(code: $viewModel.code)

            if let errorMessage = viewModel.error {
                Text(errorMessage)
                    .font(.elsfmLabel)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }

            AuthPrimaryButton(title: "Verify Email", isLoading: viewModel.isLoading) {
                viewModel.verify()
            }

            resendSection
        }
        .padding(24)
        .background(Color.elsfmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 24, y: 8)
    }

    private var resendSection: some View {
        Group {
            if viewModel.didResend {
                Text("Code resent — check your inbox.")
                    .font(.elsfmCaption)
                    .foregroundStyle(Color.elsfmTextSecondary)
                    .transition(.opacity)
            } else {
                HStack(spacing: 6) {
                    Text("Didn't receive it?")
                        .font(.elsfmCaption)
                        .foregroundStyle(Color.elsfmTextSecondary)

                    Button {
                        viewModel.resendCode()
                    } label: {
                        Text("Resend")
                            .font(.elsfmCaption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.elsfmPrimary)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.didResend)
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
                Text("Email verified!")
                    .font(.elsfmHero)
                    .foregroundStyle(Color.elsfmText)

                Text("Your account is ready. Sign in to start listening.")
                    .font(.elsfmCaption)
                    .foregroundStyle(Color.elsfmTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            AuthPrimaryButton(title: "Continue to Sign In", isLoading: false) {
                // Pop all the way back to LoginView by dismissing twice.
                // The SignupView clears registeredEmail, which collapses the destination.
                dismiss()
                dismiss()
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

// MARK: - OTP Field

private struct OTPField: View {

    @Binding var code: String
    @FocusState private var isFocused: Bool

    private let digitCount = 6

    var body: some View {
        ZStack {
            // Hidden input receiver
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .opacity(0)
                .frame(width: 1, height: 1)
                .onChange(of: code) { _, newValue in
                    let filtered = String(newValue.filter { $0.isNumber }.prefix(digitCount))
                    if filtered != code { code = filtered }
                }

            // Visual digit boxes
            HStack(spacing: 10) {
                ForEach(0..<digitCount, id: \.self) { index in
                    let digits = Array(code)
                    let char = digits.count > index ? String(digits[index]) : ""
                    let isFilled = index < code.count

                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.elsfmBackground)
                            .frame(width: 46, height: 54)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        isFilled ? Color.elsfmPrimary : Color.elsfmDivider,
                                        lineWidth: isFilled ? 2 : 1
                                    )
                            )

                        Text(char)
                            .font(.elsfmTitle)
                            .foregroundStyle(Color.elsfmText)
                    }
                }
            }
            .onTapGesture {
                isFocused = true
            }
        }
        .onAppear {
            isFocused = true
        }
    }
}
