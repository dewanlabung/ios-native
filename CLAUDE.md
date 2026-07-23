# CLAUDE.md — Elsfm iOS Native

## Skills — Load These First

Before exploring this codebase, invoke these skills:
- `/elsfm-ios-build` — iOS build config, module map, critical architecture rules
- `/elsfm-api-endpoints` — All Laravel API endpoint paths + request/response shapes
- `/elsfm-features` — Complete feature inventory (smart features, tabs, OTP flow)
- `/elsfm-laravel-integration` — Response envelope format `{"data": ...}`

## Project Overview

iOS native port of `elsfm-native` (Android/Kotlin). Shares the same Laravel backend at `https://www.elsfm.com/api/v1/`.

## Quick Reference

**Generate Xcode project:**
```bash
cd /Users/siku/Documents/GitHub/ios-native
xcodegen generate
```

**Build:**
```bash
xcodebuild -project Elsfm.xcodeproj -scheme Elsfm -destination "platform=iOS Simulator,name=iPhone 16" build
```

## Module Map

```
Elsfm/App/              — @main, RootView, TabView, Navigation
Elsfm/Core/Network/     — ApiClient (URLSession), ApiResult<T>, all *Api.swift files
Elsfm/Core/Network/Auth/— SessionManager, TokenStore (Keychain), SessionEvent
Elsfm/Core/Models/      — Codable data models (Track, Album, Artist, Playlist, User…)
Elsfm/Core/Database/    — SwiftData models + DownloadsRepository
Elsfm/Core/Media/       — PlaybackService (AVQueuePlayer), PlayerState, SleepTimer
Elsfm/Core/DesignSystem/— Color+Tokens, Font+Tokens, TrackRow, MiniPlayerView, shared UI
Elsfm/Core/Common/      — Extensions, InfiniteScrollModifier
Elsfm/Features/Auth/    — Login, Signup, EmailVerify, PasswordReset
Elsfm/Features/Discovery/— HomeView + section carousels
Elsfm/Features/Player/  — FullPlayerView, MiniPlayerView, PlayerMenuView
Elsfm/Features/Library/ — LibraryView, PlaylistDetailView
Elsfm/Features/Search/  — SearchView
Elsfm/Features/Profile/ — ProfileView (own)
Elsfm/Features/UserProfile/— UserProfileView (other users)
Elsfm/Features/Artist/  — ArtistView
Elsfm/Features/Downloads/— DownloadsView
Elsfm/Features/Subscriptions/— SubscriptionsView (StoreKit 2)
Elsfm/Features/Notifications/— NotificationsView
Elsfm/Features/Comments/— CommentsView
Elsfm/Features/Settings/— SettingsView (change password, sign out, dark mode toggle)
```

## Key Patterns

**API result type** (mirrors Android `sealed interface ApiResult<T>`):
```swift
enum ApiResult<T> {
    case success(T)
    case validationError([String: [String]])
    case unauthorized
    case networkError(Error)
}
```

**ViewModel pattern** (mirrors Android `MutableStateFlow` + `collectAsStateWithLifecycle`):
```swift
@Observable
final class FooViewModel {
    private(set) var state = FooState()
    // mutate state.xxx = ... (no .update{} needed in Swift)
}
```

**State pattern**:
```swift
struct FooState {
    var isLoading = false
    var items: [Track] = []
    var error: String? = nil
}
```

**Inject singletons via Environment**:
```swift
// in ElsfmApp.swift
.environment(sessionManager)
.environment(playbackService)

// in any View
@Environment(SessionManager.self) var session
```

**Async API call pattern**:
```swift
Task {
    state.isLoading = true
    defer { state.isLoading = false }
    switch await trackApi.getLikedTracks() {
    case .success(let tracks): state.tracks = tracks
    case .validationError(let fields): state.error = fields.values.first?.first
    case .unauthorized: session.notifyExpired()
    case .networkError(let err): state.error = err.localizedDescription
    }
}
```

**Navigation**: Each tab owns a `NavigationStack` with a typed `NavigationPath`.

**Backend**:
- Base URL: `https://www.elsfm.com/`
- All endpoints: `api/v1/…`
- Auth: `Authorization: Bearer <token>` header
- **ALL responses wrapped in `{"data": ...}` envelope** — ApiClient handles this via `DataResponse<T>`, never decode `T` directly
- Errors: 422 → `{errors: {field: [msgs]}}`, 401/403 → session expired
- Home: `GET /api/v1/channel` (NOT /discovery) → returns `[Channel]`
- OTP: `POST /api/v1/auth/send-otp` + `POST /api/v1/auth/verify-otp`
- Play logging: `POST /api/v1/tracks/{id}/plays` on every track start

## Android Counterpart

Android app lives at `/Users/siku/Documents/GitHub/elsfm-native/`.
- Refer to Kotlin models in `core/model/src/main/kotlin/` for JSON field names
- Refer to Kotlin APIs in `core/network/src/main/kotlin/com/elsfm/mobile/core/network/api/` for endpoint paths
- Feature pattern: `FeatureScreen.kt` → `FeatureView.swift`, `FeatureViewModel.kt` → `FeatureViewModel.swift`, `FeatureState` data class → `FeatureState` struct
