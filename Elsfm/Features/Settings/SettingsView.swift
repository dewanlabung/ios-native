import SwiftUI

struct SettingsView: View {

    @Environment(SessionManager.self) private var sessionManager
    @Environment(PlaybackService.self) private var playbackService
    @Environment(\.apiClient) private var apiClient

    @State private var viewModel = SettingsViewModel()
    @State private var showChangePasswordSheet = false

    var body: some View {
        NavigationStack {
            List {
                accountSection
                preferencesSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.elsfmBackground)
            .scrollContentBackground(.hidden)
            .sheet(isPresented: $showChangePasswordSheet) {
                ChangePasswordSheet()
            }
            .alert("Sign Out", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
        }
    }

    private var accountSection: some View {
        Section("Account") {
            NavigationLink(destination: ChangePasswordView()) {
                HStack {
                    Text("Change Password")
                        .font(.elsfmBody)
                        .foregroundStyle(Color.elsfmText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.elsfmTextSecondary)
                }
            }

            Button(role: .destructive) {
                Task {
                    await viewModel.signOut(sessionManager: sessionManager, authApi: AuthApi(client: apiClient))
                }
            } label: {
                HStack {
                    if viewModel.isSigningOut {
                        ProgressView()
                            .tint(.red)
                    }
                    Text("Sign Out")
                        .font(.elsfmBody)
                }
            }
            .disabled(viewModel.isSigningOut)
        }
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            Toggle("Dark Mode", isOn: .init(
                get: { viewModel.prefersDarkMode },
                set: { _ in viewModel.toggleDarkMode() }
            ))
            .font(.elsfmBody)
            .tint(Color.elsfmPrimary)

            HStack {
                Text("Sleep Timer")
                    .font(.elsfmBody)
                    .foregroundStyle(Color.elsfmText)

                Spacer()

                if let millisLeft = playbackService.state.sleepTimerMillisLeft {
                    Text(formatSleepTimerDuration(millisLeft))
                        .font(.elsfmCaption)
                        .foregroundStyle(Color.elsfmTextSecondary)
                } else {
                    Text("Off")
                        .font(.elsfmCaption)
                        .foregroundStyle(Color.elsfmTextSecondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if playbackService.state.sleepTimerMillisLeft != nil {
                    playbackService.sleepTimer.cancel()
                } else {
                    playbackService.sleepTimer.start(durationMs: 5 * 60 * 1000) {
                        playbackService.pause()
                    }
                }
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("App Version")
                    .font(.elsfmBody)
                    .foregroundStyle(Color.elsfmText)

                Spacer()

                Text(appVersion)
                    .font(.elsfmCaption)
                    .foregroundStyle(Color.elsfmTextSecondary)
            }

            Button {
                if let url = URL(string: "https://apps.apple.com/app/id1234567890") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Text("Rate the App")
                        .font(.elsfmBody)
                        .foregroundStyle(Color.elsfmPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.elsfmPrimary)
                }
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func formatSleepTimerDuration(_ milliseconds: Double) -> String {
        let totalSeconds = Int(milliseconds / 1000)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

struct ChangePasswordView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(SessionManager.self) private var sessionManager
    @Environment(\.apiClient) private var apiClient

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var successMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Current Password") {
                    SecureField("Enter current password", text: $currentPassword)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(Color.elsfmText)
                }

                Section("New Password") {
                    SecureField("Enter new password", text: $newPassword)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(Color.elsfmText)
                }

                Section("Confirm Password") {
                    SecureField("Confirm new password", text: $confirmPassword)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(Color.elsfmText)
                }

                if let errorMessage = error {
                    Section {
                        Text(errorMessage)
                            .font(.elsfmCaption)
                            .foregroundStyle(.red)
                    }
                }

                if let successMsg = successMessage {
                    Section {
                        Text(successMsg)
                            .font(.elsfmCaption)
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.elsfmBackground)
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Save") {
                            changePassword()
                        }
                        .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                    }
                }
            }
        }
    }

    private func changePassword() {
        guard newPassword == confirmPassword else {
            error = "Passwords do not match."
            return
        }

        guard newPassword.count >= 8 else {
            error = "Password must be at least 8 characters."
            return
        }

        isLoading = true
        error = nil
        successMessage = nil

        Task {
            let accountApi = AccountApi(client: apiClient)
            switch await accountApi.changePassword(
                userId: 1,
                currentPassword: currentPassword,
                newPassword: newPassword
            ) {
            case .success:
                successMessage = "Password changed successfully."
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }

            case .validationError(let fields):
                error = fields.values.first?.first ?? "Failed to change password."

            case .networkError(let err):
                error = err.localizedDescription

            case .unauthorized:
                await sessionManager.notifyExpired()
            }

            isLoading = false
        }
    }
}

private struct ChangePasswordSheet: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ChangePasswordView()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") { dismiss() }
                    }
                }
        }
    }
}

#if DEBUG
#Preview {
    let sm = SessionManager()
    SettingsView()
        .environment(sm)
        .environment(PlaybackService.shared)
        .environment(\.apiClient, ApiClient(sessionManager: sm))
        .preferredColorScheme(.dark)
}
#endif
