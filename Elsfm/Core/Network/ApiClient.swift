import Foundation

// MARK: - Response Envelopes

private struct ValidationErrorResponse: Decodable {
    let errors: [String: [String]]
}

// MARK: - ApiClient

final class ApiClient {

    // MARK: - Dependencies

    private let session: URLSession
    private let sessionManager: SessionManager

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // MARK: - Init

    init(sessionManager: SessionManager = .shared, session: URLSession = .shared) {
        self.sessionManager = sessionManager
        self.session = session
    }

    // MARK: - URL Building

    private func makeURL(_ path: String) -> URL {
        URL(string: path, relativeTo: ElsfmApiConfig.baseURL)?.absoluteURL
            ?? ElsfmApiConfig.baseURL.appending(path: path)
    }

    private func makeURL(_ path: String, queryItems: [URLQueryItem]) -> URL {
        guard var components = URLComponents(
            url: makeURL(path),
            resolvingAgainstBaseURL: false
        ) else {
            return makeURL(path)
        }
        components.queryItems = (components.queryItems ?? []) + queryItems
        return components.url ?? makeURL(path)
    }

    // MARK: - Core Requests

    private func request<T: Decodable>(
        _ url: URL,
        method: String,
        body: (any Encodable)?
    ) async -> ApiResult<T> {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = sessionManager.currentToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            do {
                urlRequest.httpBody = try JSONEncoder().encode(body)
            } catch {
                return .networkError(error)
            }
        }

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .networkError(URLError(.badServerResponse))
            }

            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoded = try decoder.decode(T.self, from: data)
                    return .success(decoded)
                } catch {
                    return .networkError(error)
                }

            case 401, 403:
                await sessionManager.notifyExpired()
                return .unauthorized

            case 422:
                if let envelope = try? decoder.decode(ValidationErrorResponse.self, from: data) {
                    return .validationError(envelope.errors)
                }
                return .validationError([:])

            default:
                return .networkError(URLError(.badServerResponse))
            }

        } catch let urlError as URLError {
            return .networkError(urlError)
        } catch {
            return .networkError(error)
        }
    }

    private func voidRequest(
        _ url: URL,
        method: String,
        body: (any Encodable)? = nil
    ) async -> ApiResult<Void> {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = sessionManager.currentToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            do {
                urlRequest.httpBody = try JSONEncoder().encode(body)
            } catch {
                return .networkError(error)
            }
        }

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .networkError(URLError(.badServerResponse))
            }

            switch httpResponse.statusCode {
            case 200...299:
                return .success(())

            case 401, 403:
                await sessionManager.notifyExpired()
                return .unauthorized

            case 422:
                if let envelope = try? decoder.decode(ValidationErrorResponse.self, from: data) {
                    return .validationError(envelope.errors)
                }
                return .validationError([:])

            default:
                return .networkError(URLError(.badServerResponse))
            }

        } catch let urlError as URLError {
            return .networkError(urlError)
        } catch {
            return .networkError(error)
        }
    }

    // MARK: - Convenience: GET

    func get<T: Decodable>(_ path: String) async -> ApiResult<T> {
        await request(makeURL(path), method: "GET", body: nil as EmptyBody?)
    }

    func get<T: Decodable>(_ path: String, queryItems: [URLQueryItem]) async -> ApiResult<T> {
        await request(makeURL(path, queryItems: queryItems), method: "GET", body: nil as EmptyBody?)
    }

    // MARK: - Convenience: POST

    func post<T: Decodable>(_ path: String, body: some Encodable) async -> ApiResult<T> {
        await request(makeURL(path), method: "POST", body: body)
    }

    func post(_ path: String) async -> ApiResult<Void> {
        await voidRequest(makeURL(path), method: "POST")
    }

    func post<B: Encodable>(_ path: String, body: B) async -> ApiResult<Void> {
        await voidRequest(makeURL(path), method: "POST", body: body)
    }

    // MARK: - Convenience: PUT

    func put<T: Decodable>(_ path: String, body: some Encodable) async -> ApiResult<T> {
        await request(makeURL(path), method: "PUT", body: body)
    }

    func put<B: Encodable>(_ path: String, body: B) async -> ApiResult<Void> {
        await voidRequest(makeURL(path), method: "PUT", body: body)
    }

    // MARK: - Convenience: DELETE

    func delete(_ path: String) async -> ApiResult<Void> {
        await voidRequest(makeURL(path), method: "DELETE")
    }
}

// MARK: - Helpers

private struct EmptyBody: Encodable {}
