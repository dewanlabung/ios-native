import Foundation
import Observation

@Observable
@MainActor
final class NotificationsViewModel {

    var notifications: [AppNotification] = []
    var isLoading = false
    var error: String?
    var hasMore = false
    var currentPage = 1

    private let api: NotificationsApi
    private let perPage = 20
    private var isLoadingMore = false

    init(api: NotificationsApi) {
        self.api = api
    }

    func loadNotifications() {
        Task {
            isLoading = true
            error = nil
            defer { isLoading = false }
            switch await api.getNotifications(page: 1) {
            case .success(let items):
                notifications = items
                currentPage = 1
                hasMore = items.count >= perPage
            case .validationError(let fields):
                error = fields.values.first?.first
            case .unauthorized:
                error = "Session expired. Please log in again."
            case .networkError(let err):
                error = err.localizedDescription
            }
        }
    }

    func loadMore() {
        guard hasMore, !isLoading, !isLoadingMore else { return }
        Task {
            isLoadingMore = true
            defer { isLoadingMore = false }
            let nextPage = currentPage + 1
            switch await api.getNotifications(page: nextPage) {
            case .success(let items):
                if items.isEmpty {
                    hasMore = false
                } else {
                    notifications.append(contentsOf: items)
                    currentPage = nextPage
                    hasMore = items.count >= perPage
                }
            case .validationError, .networkError, .unauthorized:
                break
            }
        }
    }

    func markAllRead() {
        Task {
            switch await api.markAllAsRead() {
            case .success:
                let now = ISO8601DateFormatter().string(from: Date())
                notifications = notifications.map { n in
                    guard n.readAt == nil else { return n }
                    return AppNotification(
                        id: n.id,
                        type: n.type,
                        data: n.data,
                        readAt: now,
                        createdAt: n.createdAt
                    )
                }
            case .validationError(let fields):
                error = fields.values.first?.first
            case .unauthorized:
                error = "Session expired. Please log in again."
            case .networkError(let err):
                error = err.localizedDescription
            }
        }
    }
}
