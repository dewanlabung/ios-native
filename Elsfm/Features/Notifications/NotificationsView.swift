import SwiftUI

struct NotificationsView: View {

    @Environment(\.apiClient) private var apiClient
    @State private var viewModel: NotificationsViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                if vm.isLoading && vm.notifications.isEmpty {
                    loadingState
                } else if vm.notifications.isEmpty {
                    emptyState
                } else {
                    feedList(vm: vm)
                }
            } else {
                loadingState
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .background(Color.elsfmBackground)
        .onFirstAppear {
            let vm = NotificationsViewModel(api: NotificationsApi(client: apiClient))
            viewModel = vm
            vm.loadNotifications()
        }
    }

    private var loadingState: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.elsfmBackground)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.elsfmTextSecondary)

            Text("No notifications yet")
                .font(.elsfmBody)
                .foregroundStyle(Color.elsfmTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.elsfmBackground)
    }

    private func feedList(vm: NotificationsViewModel) -> some View {
        List {
            if let errorMessage = vm.error {
                Text(errorMessage)
                    .font(.elsfmCaption)
                    .foregroundStyle(Color.elsfmPrimary)
                    .listRowBackground(Color.elsfmSurface)
            }

            ForEach(vm.notifications) { notification in
                NotificationRow(notification: notification)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(
                        notification.readAt == nil
                            ? Color.elsfmPrimary.opacity(0.07)
                            : Color.elsfmSurface
                    )
                    .listRowSeparatorTint(Color.elsfmDivider)
            }

            Color.clear
                .frame(height: 1)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .onReachBottom {
                    vm.loadMore()
                }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.elsfmBackground)
        .refreshable { vm.loadNotifications() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                let hasUnread = vm.notifications.contains { $0.readAt == nil }
                if hasUnread {
                    Button("Mark all read") {
                        vm.markAllRead()
                    }
                    .font(.elsfmCaption)
                    .foregroundStyle(Color.elsfmPrimary)
                }
            }
        }
    }
}

private struct NotificationRow: View {

    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            notificationIcon

            VStack(alignment: .leading, spacing: 3) {
                if let title = notification.data?.title {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.elsfmText)
                        .lineLimit(1)
                }

                if let body = notification.data?.body {
                    Text(body)
                        .font(.elsfmCaption)
                        .foregroundStyle(Color.elsfmText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(relativeTime(from: notification.createdAt))
                    .font(.elsfmCaption)
                    .foregroundStyle(Color.elsfmTextSecondary)
                    .padding(.top, 2)
            }

            Spacer(minLength: 0)

            if notification.readAt == nil {
                Circle()
                    .fill(Color.elsfmPrimary)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var notificationIcon: some View {
        let (symbol, color) = iconConfig(for: notification.type)
        return ZStack {
            Circle()
                .fill(color.opacity(0.14))
                .frame(width: 42, height: 42)
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(color)
        }
    }

    private func iconConfig(for type: String) -> (String, Color) {
        let t = type.lowercased()
        if t.contains("like") || t.contains("heart") {
            return ("heart.fill", .elsfmPrimary)
        } else if t.contains("comment") || t.contains("reply") {
            return ("bubble.left.fill", Color(red: 0.2, green: 0.78, blue: 0.35))
        } else if t.contains("follow") {
            return ("person.fill.badge.plus", Color(red: 0.2, green: 0.6, blue: 1.0))
        } else if t.contains("repost") || t.contains("share") {
            return ("arrow.2.squarepath", Color(red: 0.6, green: 0.4, blue: 1.0))
        } else if t.contains("playlist") {
            return ("music.note.list", Color(red: 1.0, green: 0.6, blue: 0.2))
        } else if t.contains("album") {
            return ("square.stack.fill", Color(red: 0.4, green: 0.7, blue: 1.0))
        } else if t.contains("track") || t.contains("upload") || t.contains("song") {
            return ("music.note", Color(red: 0.9, green: 0.5, blue: 0.9))
        } else {
            return ("bell.fill", Color.elsfmPrimary)
        }
    }

    private func relativeTime(from isoString: String) -> String {
        var formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: isoString)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: isoString)
        }
        guard let date else { return "" }

        let elapsed = Int(-date.timeIntervalSinceNow)
        switch elapsed {
        case ..<60:
            return "just now"
        case 60..<3600:
            let m = elapsed / 60
            return "\(m)m ago"
        case 3600..<86400:
            let h = elapsed / 3600
            return "\(h)h ago"
        case 86400..<604800:
            let d = elapsed / 86400
            return "\(d)d ago"
        default:
            let w = elapsed / 604800
            return "\(w)w ago"
        }
    }
}
