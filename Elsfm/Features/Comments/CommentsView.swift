import SwiftUI

struct CommentsView: View {
    let trackId: Int
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CommentsViewModel?
    @Environment(\.apiClient) private var apiClient

    var body: some View {
        NavigationStack {
            ZStack {
                Color.elsfmBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    headerView
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .borderBottom(color: .elsfmDivider)

                    if let viewModel = viewModel {
                        commentsListView(viewModel)
                    } else {
                        ProgressView()
                            .tint(.elsfmPrimary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                let api = CommentApi(client: apiClient)
                let vm = CommentsViewModel(trackId: trackId, api: api)
                viewModel = vm
                vm.loadComments()
            }
        }
    }

    private var headerView: some View {
        HStack {
            Text("Comments")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.elsfmText)

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.elsfmTextSecondary)
                    .frame(width: 32, height: 32)
            }
        }
    }

    private func commentsListView(_ viewModel: CommentsViewModel) -> some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.comments.isEmpty {
                VStack {
                    ProgressView()
                        .tint(.elsfmPrimary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.comments.isEmpty {
                VStack(spacing: 12) {
                    Text("No comments yet")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.elsfmTextSecondary)

                    Text("Be the first to comment")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.elsfmTextSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 48)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.comments) { comment in
                            commentRow(comment)
                                .borderBottom(color: .elsfmDivider)
                        }
                    }
                }
            }

            if let error = viewModel.error, !error.isEmpty {
                VStack(spacing: 8) {
                    Text(error)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.elsfmPrimary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.elsfmPrimary.opacity(0.1))
                .borderBottom(color: .elsfmDivider)
            }

            commentInputView(viewModel)
        }
    }

    private func commentRow(_ comment: Comment) -> some View {
        HStack(alignment: .top, spacing: 12) {
            avatarCircle(for: comment.user)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(userDisplayName(comment.user))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.elsfmText)

                    Text(timeAgo(from: comment.createdAt))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.elsfmTextSecondary)

                    Spacer()
                }

                Text(comment.body)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.elsfmText)
                    .lineLimit(nil)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 8)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    private func avatarCircle(for user: User?) -> some View {
        let initials = initials(for: user)
        return Circle()
            .fill(Color.elsfmPrimary)
            .frame(width: 36, height: 36)
            .overlay(
                Text(initials)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.elsfmOnPrimary)
            )
    }

    private func commentInputView(_ viewModel: CommentsViewModel) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                TextField("Add a comment...", text: Bindable(viewModel).newCommentText, axis: .vertical)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.elsfmText)
                    .tint(.elsfmPrimary)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color.elsfmSurface)
                    .cornerRadius(8)
                    .lineLimit(3...5)

                Button(action: { viewModel.postComment() }) {
                    if viewModel.isPosting {
                        ProgressView()
                            .tint(.elsfmPrimary)
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.elsfmOnPrimary)
                    }
                }
                .frame(width: 40, height: 40)
                .background(Color.elsfmPrimary)
                .cornerRadius(8)
                .disabled(viewModel.newCommentText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isPosting)
                .opacity(viewModel.newCommentText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isPosting ? 0.5 : 1)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.elsfmBackground)
            .borderTop(color: .elsfmDivider)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private func userDisplayName(_ user: User?) -> String {
        guard let name = user?.name?.trimmingCharacters(in: .whitespaces), !name.isEmpty else {
            return "Anonymous"
        }
        return name
    }

    private func initials(for user: User?) -> String {
        guard let name = user?.name?.trimmingCharacters(in: .whitespaces), !name.isEmpty else {
            return "U"
        }
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(1)).uppercased()
    }

    private func timeAgo(from dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: dateString) else {
            return "now"
        }

        let elapsed = Date().timeIntervalSince(date)

        if elapsed < 60 {
            return "now"
        } else if elapsed < 3600 {
            let minutes = Int(elapsed / 60)
            return "\(minutes)m ago"
        } else if elapsed < 86400 {
            let hours = Int(elapsed / 3600)
            return "\(hours)h ago"
        } else if elapsed < 604800 {
            let days = Int(elapsed / 86400)
            return "\(days)d ago"
        } else {
            let weeks = Int(elapsed / 604800)
            return "\(weeks)w ago"
        }
    }
}

extension View {
    fileprivate func borderBottom(color: Color) -> some View {
        VStack(spacing: 0) {
            self
            Divider()
                .background(color)
        }
    }

    fileprivate func borderTop(color: Color) -> some View {
        VStack(spacing: 0) {
            Divider()
                .background(color)
            self
        }
    }
}

#Preview {
    CommentsView(trackId: 1)
        .environment(\.apiClient, ApiClient(sessionManager: SessionManager()))
}
