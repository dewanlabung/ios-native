# Graph Report - .  (2026-07-24)

## Corpus Check
- Corpus is ~36,225 words - fits in a single context window. You may not need a graph.

## Summary
- 911 nodes · 2296 edges · 56 communities (44 shown, 12 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 215 edges (avg confidence: 0.81)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Core Data Models
- Auth Session Layer
- Navigation & Views
- Player State Machine
- Playback Engine
- Test Suite
- App Destinations
- Skills & Documentation
- Search Feature
- Downloads Repository
- Model Files
- App Shell & Design System
- User Social API
- Profile Feature
- Content APIs
- Push Notifications
- Playlist Detail
- Full Player View
- Artist Detail
- Registration Flow
- Community 20
- Community 21
- Community 22
- Community 23
- Community 24
- Community 25
- Community 26
- Community 27
- Community 28
- Community 29
- Community 30
- Community 31
- Community 32
- Community 33
- Community 34
- Community 35
- Community 36
- Community 37
- Community 38
- Community 39
- Community 40
- Community 41
- Community 42
- Community 43
- Community 44
- Community 45
- Community 46
- Community 47
- Community 48
- Community 49
- Community 50
- Community 51
- Community 52
- Community 53
- Community 54
- Community 55

## God Nodes (most connected - your core abstractions)
1. `String` - 159 edges
2. `Int` - 101 edges
3. `ApiResult` - 79 edges
4. `Foundation` - 71 edges
5. `Track` - 59 edges
6. `ApiClient` - 57 edges
7. `PlaybackService` - 43 edges
8. `SwiftUI` - 36 edges
9. `Playlist` - 28 edges
10. `SessionManager` - 27 edges

## Surprising Connections (you probably didn't know these)
- `MockAuthApi` --references--> `String`  [EXTRACTED]
  ElsfmTests/Auth/LoginViewModelTests.swift → Elsfm/Core/Common/Extensions.swift
- `MockTokenStore` --references--> `String`  [EXTRACTED]
  ElsfmTests/Auth/LoginViewModelTests.swift → Elsfm/Core/Common/Extensions.swift
- `MockAuthApi` --references--> `ApiResult`  [EXTRACTED]
  ElsfmTests/Auth/LoginViewModelTests.swift → Elsfm/Core/Network/ApiResult.swift
- `KeychainAccess (SPM Package v4.2+)` --conceptually_related_to--> `SessionManager (iOS Auth Session + Keychain Token)`  [INFERRED]
  project.yml → .claude/skills/elsfm-ios-build/SKILL.md
- `EnvironmentValues` --references--> `ApiClient`  [EXTRACTED]
  Elsfm/App/ElsfmApp.swift → Elsfm/Core/Network/ApiClient.swift

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **ELSFM Authentication Flow (Sanctum Bearer Token across iOS + Laravel)** — _claude_skills_elsfm_api_endpoints_skill, _claude_skills_elsfm_ios_build_skill_sessionmanager, project_yml_keychainaccess, _claude_skills_elsfm_laravel_backend_references_authorization_basepolicy [INFERRED 0.85]
- **ELSFM Response Envelope {data:...} Pattern (iOS + Flutter + Laravel)** — _claude_skills_elsfm_ios_build_skill_dataresponse, _claude_skills_elsfm_laravel_backend_references_controllers_pattern_basecontroller, _claude_skills_elsfm_laravel_integration_references_response_mapping_paginatedresult, _claude_skills_elsfm_laravel_integration_references_response_mapping [EXTRACTED 1.00]
- **common/foundation Shared Package Layer (BaseUser, BaseChannel, BaseController, BasePolicy, Datasource)** — _claude_skills_elsfm_laravel_integration_references_common_foundation_package, _claude_skills_elsfm_laravel_backend_references_models_relationships_baseuser, _claude_skills_elsfm_laravel_backend_references_models_relationships_basechannel, _claude_skills_elsfm_laravel_backend_references_authorization_basepolicy, _claude_skills_elsfm_laravel_backend_references_controllers_pattern_basecontroller, _claude_skills_elsfm_laravel_backend_references_datasource_pagination_datasource [EXTRACTED 1.00]
- **ELSFM iOS Media Layer (PlaybackService + ShakeDetector + HeadsetEventMonitor)** — _claude_skills_elsfm_ios_build_skill_playbackservice, _claude_skills_elsfm_ios_build_skill_shakedetector, _claude_skills_elsfm_ios_build_skill [EXTRACTED 1.00]

## Communities (56 total, 12 thin omitted)

### Community 0 - "Core Data Models"
Cohesion: 0.06
Nodes (50): Codable, Int, Album, AppNotification, NotificationData, Artist, Bool, ArtistFollower (+42 more)

### Community 1 - "Auth Session Layer"
Cohesion: 0.07
Nodes (19): AsyncStream, LoginResponse, AuthApi, AuthApiProtocol, SessionEvent, expired, SessionManager, TokenStore (+11 more)

### Community 2 - "Navigation & Views"
Cohesion: 0.06
Nodes (22): AppDestinationsModifier, Content, View, View, OnFirstAppearModifier, Content, View, Void (+14 more)

### Community 3 - "Player State Machine"
Cohesion: 0.07
Nodes (15): PlayerRepeatMode, all, off, one, PlayerState, Bool, Double, Float (+7 more)

### Community 4 - "Playback Engine"
Cohesion: 0.12
Nodes (10): Any, PlaybackService, Bool, Double, Float, Never, Task, URL (+2 more)

### Community 5 - "Test Suite"
Cohesion: 0.08
Nodes (6): Elsfm, TrackCodableTests, ApiResultTests, JSONDecoder, XCTest, XCTestCase

### Community 6 - "App Destinations"
Cohesion: 0.11
Nodes (21): CaseIterable, AppDestination, album, artist, comments, downloads, notifications, playlist (+13 more)

### Community 7 - "Skills & Documentation"
Cohesion: 0.09
Nodes (36): ELSFM API Endpoints Skill, ELSFM Features Inventory Skill (Android), ELSFM iOS Build Skill, ApiResult<T> Swift Enum (success / validationError / unauthorized / networkError), DataResponse<T> API Response Envelope Wrapper (iOS), PlaybackService (AVQueuePlayer iOS Media Layer), SessionManager (iOS Auth Session + Keychain Token), ShakeDetector (CoreMotion iOS Smart Feature) (+28 more)

### Community 8 - "Search Feature"
Cohesion: 0.10
Nodes (23): SearchApi, AlbumRow, ArtistRow, errorView(), init(), PlaylistRow, SearchStateView, Bool (+15 more)

### Community 9 - "Downloads Repository"
Cohesion: 0.14
Nodes (10): DownloadedTrack, Date, DownloadsRepository, Bool, URL, DownloadedTrackRow, DownloadsView, Void (+2 more)

### Community 11 - "App Shell & Design System"
Cohesion: 0.10
Nodes (11): RootView, UIColor, Font, LikeButton, Bool, Void, OfflineBanner, Void (+3 more)

### Community 12 - "User Social API"
Cohesion: 0.20
Nodes (5): Void, UserApi, UserProfileView, Bool, UserProfileViewModel

### Community 13 - "Profile Feature"
Cohesion: 0.19
Nodes (6): EditProfileSheet, PlaylistRow, ProfileView, ProfileViewModel, PhotosPickerItem, PhotosUI

### Community 14 - "Content APIs"
Cohesion: 0.15
Nodes (7): ChannelApi, LyricsApi, RepostApi, SessionsApi, TrackListApi, ApiClient, URLSession

### Community 15 - "Push Notifications"
Cohesion: 0.17
Nodes (6): NotificationsApi, PushTokenRequest, Void, NotificationRow, NotificationsView, NotificationsViewModel

### Community 16 - "Playlist Detail"
Cohesion: 0.23
Nodes (6): PlaylistDetailView, PlaylistHeader, ToolbarContent, Void, PlaylistDetailState, PlaylistDetailViewModel

### Community 17 - "Full Player View"
Cohesion: 0.24
Nodes (9): FullPlayerView, SleepTimerSheet, Bool, CGFloat, Double, ToolbarContent, Void, MiniPlayerView (+1 more)

### Community 18 - "Artist Detail"
Cohesion: 0.27
Nodes (3): ArtistDetailView, ArtistViewModel, Bool

### Community 19 - "Registration Flow"
Cohesion: 0.18
Nodes (6): String, Bool, RegisterBody, KeychainTokenStore, LyricsView, Bool

### Community 20 - "Community 20"
Cohesion: 0.18
Nodes (8): ProductCard, SubscriptionsView, Bool, Product, Void, SubscriptionsViewModel, Product, StoreKit

### Community 21 - "Community 21"
Cohesion: 0.19
Nodes (7): PasswordResetView, AuthApi, PasswordResetPhase, complete, request, PasswordResetViewModel, AuthApi

### Community 22 - "Community 22"
Cohesion: 0.17
Nodes (9): App, ApiClientKey, ElsfmApp, EnvironmentValues, ModelContainer, ElsfmDatabase, ModelContainer, EnvironmentKey (+1 more)

### Community 23 - "Community 23"
Cohesion: 0.24
Nodes (3): Void, TrackApi, PlayerViewModel

### Community 24 - "Community 24"
Cohesion: 0.29
Nodes (4): AuthApi, SendOtpRequest, Void, VerifyOtpRequest

### Community 25 - "Community 25"
Cohesion: 0.22
Nodes (5): EmailVerifyView, OTPField, Bool, EmailVerifyViewModel, AuthApi

### Community 26 - "Community 26"
Cohesion: 0.47
Nodes (5): B, Encodable, T, URL, Void

### Community 27 - "Community 27"
Cohesion: 0.24
Nodes (7): Decodable, ApiError, BootstrapData, RegisterResponse, DataResponse, EmptyBody, ValidationErrorResponse

### Community 28 - "Community 28"
Cohesion: 0.24
Nodes (8): AsyncImageView, FallbackThumbnail, ShimmerPlaceholder, CGFloat, AlbumCell, ArtistBannerView, CGFloat, Kingfisher

### Community 29 - "Community 29"
Cohesion: 0.24
Nodes (6): PasswordResetRequest, PostCommentRequest, CreatePlaylistRequest, TrackIdRequest, UpdatePlaylistRequest, Encodable

### Community 30 - "Community 30"
Cohesion: 0.22
Nodes (6): CoreMotion, ShakeDetector, Date, Double, Void, TimeInterval

### Community 31 - "Community 31"
Cohesion: 0.22
Nodes (9): CodingKeys, album, artists, durationMs, id, image, name, plays (+1 more)

### Community 33 - "Community 33"
Cohesion: 0.28
Nodes (8): AuthPrimaryButton, AuthSecureField, AuthTextField, FieldErrorView, GoogleSignInButton, Bool, Void, UIKeyboardType

### Community 34 - "Community 34"
Cohesion: 0.25
Nodes (8): PlaybackSpeed, double, half, normal, oneAndHalf, oneAndQuarter, threeQuarters, Float

### Community 35 - "Community 35"
Cohesion: 0.25
Nodes (8): CodingKey, CodingKeys, bootstrapData, CodingKeys, email, password, passwordConfirmation, tokenName

### Community 37 - "Community 37"
Cohesion: 0.29
Nodes (6): MainTabView, Tab, discovery, library, profile, search

### Community 38 - "Community 38"
Cohesion: 0.29
Nodes (6): CodingKeys, email, password, passwordConfirmation, token, CompletePasswordResetRequest

### Community 39 - "Community 39"
Cohesion: 0.29
Nodes (5): CodingKeys, email, password, tokenName, LoginRequest

### Community 43 - "Community 43"
Cohesion: 0.29
Nodes (7): ArtistTab, about, albums, discography, followers, similarArtists, tracks

### Community 44 - "Community 44"
Cohesion: 0.38
Nodes (3): DownloadMenuRow, PlayerMenuView, Void

### Community 45 - "Community 45"
Cohesion: 0.33
Nodes (5): AuthDestination, emailVerify, passwordReset, signup, AuthRootView

### Community 46 - "Community 46"
Cohesion: 0.33
Nodes (5): CodingKeys, email, password, passwordConfirmation, RegisterRequest

### Community 48 - "Community 48"
Cohesion: 0.60
Nodes (4): CGFloat, Void, TrackCard, TrackSectionView

### Community 50 - "Community 50"
Cohesion: 0.67
Nodes (3): AlbumCard, AlbumSectionView, CGFloat

### Community 51 - "Community 51"
Cohesion: 0.67
Nodes (3): ArtistCard, ArtistSectionView, CGFloat

## Knowledge Gaps
- **82 isolated node(s):** `signup`, `emailVerify`, `passwordReset`, `artist`, `album` (+77 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **12 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `Registration Flow` to `Core Data Models`, `Auth Session Layer`, `Navigation & Views`, `Player State Machine`, `Playback Engine`, `Test Suite`, `App Destinations`, `Search Feature`, `Downloads Repository`, `App Shell & Design System`, `User Social API`, `Profile Feature`, `Push Notifications`, `Playlist Detail`, `Full Player View`, `Artist Detail`, `Community 20`, `Community 21`, `Community 23`, `Community 24`, `Community 25`, `Community 26`, `Community 27`, `Community 28`, `Community 29`, `Community 31`, `Community 33`, `Community 34`, `Community 35`, `Community 36`, `Community 38`, `Community 39`, `Community 42`, `Community 43`, `Community 44`, `Community 45`, `Community 46`, `Community 47`?**
  _High betweenness centrality (0.419) - this node is a cross-community bridge._
- **Why does `Int` connect `Core Data Models` to `Navigation & Views`, `Playback Engine`, `Community 37`, `App Destinations`, `Downloads Repository`, `Community 41`, `Community 42`, `User Social API`, `Profile Feature`, `Community 47`, `Playlist Detail`, `Push Notifications`, `Artist Detail`, `Registration Flow`, `Community 23`, `Community 29`?**
  _High betweenness centrality (0.119) - this node is a cross-community bridge._
- **Why does `Track` connect `Core Data Models` to `Player State Machine`, `Playback Engine`, `Test Suite`, `App Destinations`, `Search Feature`, `Downloads Repository`, `App Shell & Design System`, `Community 44`, `Profile Feature`, `User Social API`, `Community 48`, `Community 49`, `Artist Detail`, `Registration Flow`, `Playlist Detail`, `Full Player View`, `Community 31`?**
  _High betweenness centrality (0.080) - this node is a cross-community bridge._
- **What connects `signup`, `emailVerify`, `passwordReset` to the rest of the system?**
  _82 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Core Data Models` be split into smaller, more focused modules?**
  _Cohesion score 0.0596039603960396 - nodes in this community are weakly interconnected._
- **Should `Auth Session Layer` be split into smaller, more focused modules?**
  _Cohesion score 0.06892230576441102 - nodes in this community are weakly interconnected._
- **Should `Navigation & Views` be split into smaller, more focused modules?**
  _Cohesion score 0.06161616161616162 - nodes in this community are weakly interconnected._