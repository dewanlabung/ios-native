import Foundation
import Observation

@Observable @MainActor
final class CommentsViewModel {
    private(set) var comments: [Comment] = []
    var newCommentText = ""
    private(set) var isLoading = false
    private(set) var isPosting = false
    var error: String?

    let trackId: Int
    private let api: CommentApi

    init(trackId: Int, api: CommentApi) {
        self.trackId = trackId
        self.api = api
    }

    func loadComments() {
        isLoading = true
        error = nil

        Task {
            let result = await api.getComments(trackId: trackId, page: 1)
            switch result {
            case .success(let comments):
                self.comments = comments
                self.isLoading = false
            case .validationError(let fields):
                self.error = fields.values.first?.first ?? "Validation error"
                self.isLoading = false
            case .unauthorized:
                self.error = "Unauthorized"
                self.isLoading = false
            case .networkError(let err):
                self.error = err.localizedDescription
                self.isLoading = false
            }
        }
    }

    func postComment() {
        let text = newCommentText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        isPosting = true
        error = nil

        Task {
            let result = await api.postComment(trackId: trackId, body: text)
            switch result {
            case .success(let comment):
                self.comments.insert(comment, at: 0)
                self.newCommentText = ""
                self.isPosting = false
            case .validationError(let fields):
                self.error = fields.values.first?.first ?? "Validation error"
                self.isPosting = false
            case .unauthorized:
                self.error = "Unauthorized"
                self.isPosting = false
            case .networkError(let err):
                self.error = err.localizedDescription
                self.isPosting = false
            }
        }
    }
}
