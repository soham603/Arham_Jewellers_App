# AGENTS.md

Instructions for AI coding agents working in this repository.

## Project Overview

**Brand name: Shree Arham Gold & Ratnesh Gold** — use this branding across UI, metadata, and content.

Shree Arham Gold & Ratnesh Gold mobile app — Flutter e-commerce application for the jewellery business, containing both:

- **Storefront** — customer-facing shopping experience (products, search, cart, checkout, orders, wishlist, profile)
- **Admin panel** — internal dashboard for managing products, orders, users, gold rates, and content

The customer/admin split is driven at runtime by `AuthController.isAdmin` (`lib/presentation/pages/main_shell_view.dart`), which swaps the bottom-nav pages and routes.

### Sibling Projects

This repo is part of a larger system. Two sibling directories sit alongside it:

| Directory | Stack | Notes |
|---|---|---|
| `../Arham_Jewellers_Web-App` | Next.js, React, TypeScript, Tailwind, shadcn/ui | Web storefront + admin. Reference for features, UI, API usage |
| `../Arham_Jewellers_Backend` | Node.js, TypeScript, Express 5, Prisma, PostgreSQL | REST API backend |

- Never modify files in sibling directories from this repo.
- This repo is the authoritative **API endpoint reference** — the live base URL and all endpoints live in `lib/core/constants/ApiUrlConstants.dart`.

## Tech Stack

- **Framework:** Flutter (Dart SDK ^3.10.8), targeting Android, iOS, web, macOS, Windows, Linux
- **State management:** GetX (`Get.put` / `Get.find` / `.obs` / `Rx*`)
- **Networking:** dio via a central client in `lib/core/restServices/apiService.dart` (`BaseHttpService`)
- **Auth/storage:** `flutter_secure_storage` (tokens/user) + `shared_preferences` (UI prefs)
- **Notifications:** Firebase Cloud Messaging + `flutter_local_notifications`
- **Other:** `cached_network_image`, `pdf`/`share_plus`, `mobile_scanner`, `no_screenshot`, `fl_chart`

## Commands

```bash
flutter pub get   # install/resolve dependencies
flutter analyze   # static analysis (flutter_lints)
flutter test      # run widget/unit tests
dart format .     # format code (Formatter uses single quotes)
flutter build apk # / ios / web / etc. — build a release target
```

Before considering any task complete, run `flutter analyze` and `flutter test`. Fix all errors you introduced.

## Directory Conventions

```
lib/
  app/                  # GetMaterialApp, routes (app_routes.dart, app_pages.dart)
  core/
    constants/          # ApiUrlConstants.dart, admin/karat/image/timeout constants
    restServices/       # apiService.dart — the central dio client + interceptors
    theme/              # app_theme.dart, app_colors.dart
    widgets/            # shared UI widgets
    utils/              # formatters, error helpers, etc.
  data/repositories/    # repository implementations extending BaseRepository
  domain/
    entities/           # models (ProductModel, UserModel, ...)
    repositories/       # abstract interfaces (i_product_repository.dart, ...)
  presentation/
    controllers/        # GetX controllers (auth, cart, admin/*, ...)
    pages/              # screens (home, search, product, cart, checkout, admin, ...)
    shimmers/           # loading placeholders
  services/             # Dependencies.dart, deviceIdService.dart, notification_service.dart
  utils/                # legacy helpers (SessionManager, ToastUtil, ColorPallete, ...)
```

- Layer pattern: `presentation` → `domain` (interfaces) ← `data/repositories` (dio calls). Repositories share the singleton `httpClient` exposed by `lib/services/Dependencies.dart`.
- Every API call goes through the `BaseHttpService` interceptor in `lib/core/restServices/apiService.dart`, which: injects `Authorization: Bearer <token>`, retries 502/503/504 once, refreshes tokens on 401 (deduplicated via a shared completer), and redirects to `/login` when the session is unrecoverable. Requests that must skip auth pass `Options(extra: {"requiresAuth": false})`.
- Sessions are device-bound. Logins must send `deviceId` from `getDeviceId()` (`lib/services/deviceIdService.dart`). Tokens, expiry, user data, and the admin flag are persisted via `SessionManager` (`lib/utils/SessionManager.dart`).
- Controllers use observable state (`CurrentAppState`, `.obs`) and expose getters rather than mutating `Rx` fields externally. Match that pattern in new controllers.

## Environment

- Secrets/config live in `.env*` files, `android/key.properties`, and keystores — all gitignored. Never commit them.
- `android/app/google-services.json` (Firebase config) is committed and required for push notifications; avoid unnecessary churn to it.
- Never hardcode API keys, tokens, or credentials in code.

## Test Credentials (live backend)

For verifying flows against `https://api.ratneshgold.com/`. Test accounts only — never use in production code or commit anywhere else.

| Role | Phone | Password |
|---|---|---|
| Admin | +919879879870 | Admin@1234 |
| Customer | +918097137041 | Parth@1234 |

Notes:

- The app normalizes 10-digit numbers to `+91XXXXXXXXXX`; the raw API requires the international format.
- Customer accounts are device-bound on the backend. The app sends the real device id from `getDeviceId()`; for direct API logins outside the app, pass the registered device (`SP1A.210812.016`) — otherwise login fails with `Device mismatch`.
- Admin and customer use separate endpoints (`user-login` vs `admin-login`); the app chooses based on account type and stores the result in the `isAdmin` flag.

## Code Style

- Match existing style in the repo; use idiomatic Flutter/Dart conventions.
- No code comments unless explicitly requested.
- Prefer GetX patterns already in use (`Get.put` in `main.dart`/controllers, `Obx`/`GetBuilder` in widgets). Register long-lived controllers in `lib/main.dart` `_registerControllers()` or on demand with `Get.put`.
- Keep models' `fromJson`/`toJson` in `lib/domain/entities` and model them from actual backend JSON responses, not assumptions.
- Ask before adding any new dependency to `pubspec.yaml`.

## Git Rules

- Never commit unless explicitly asked.
- Never commit secrets, `.env*`, lockfile churn without cause, or unrelated files.