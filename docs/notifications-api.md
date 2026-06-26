# Notifications API

## Base URL

```
https://arham-jewellers-backend.onrender.com
```

---

## Overview

The notification system is built on three layers:

1. **Firebase Cloud Messaging (FCM)** — push notifications delivered from the backend to devices via FCM topics/tokens.
2. **Local Notifications** — in-app system-level notifications rendered by `flutter_local_notifications` (used for foreground messages and in-app triggers like order status changes).
3. **In-App Notification List** — a persistent list stored locally (`SharedPreferences`) and synced with the backend via REST endpoints, surfaced on the `NotificationsPage`.

---

## Endpoints

### 1. Get All Notifications (User)

```
GET /api/v1/notifications/get-all
```

Returns paginated notifications for the authenticated user.

#### Headers

```
Authorization: Bearer <user_jwt_token>
```

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `page` | int | No | `1` | Page number (1-indexed) |
| `limit` | int | No | `20` | Items per page |

#### Response (200)

```json
{
  "data": {
    "notifications": [
      {
        "id": "abc123",
        "title": "Order Shipped",
        "body": "Your order #1234 has been shipped.",
        "message": "Your order #1234 has been shipped.",
        "createdAt": "2026-06-25T10:30:00.000Z",
        "isRead": false,
        "data": {
          "route": "/user-order-detail",
          "orderId": "1234"
        }
      }
    ]
  }
}
```

#### Notes

- `body` may be returned as `message` from the backend; the app handles both keys.
- `data` is an optional map containing navigation info (e.g. `route`, `orderId`).
- Max 100 notifications are retained locally; older ones are trimmed.

---

### 2. Mark Notifications as Read

```
PATCH /api/v1/notifications/action
```

Marks one or more notifications as read for the authenticated user.

#### Headers

```
Authorization: Bearer <user_jwt_token>
Content-Type: application/json
```

#### Request Body

```json
{
  "notificationIds": ["abc123", "def456"]
}
```

#### Response (200)

```json
{
  "message": "Notifications marked as read"
}
```

---

### 3. Send Notification (Admin)

```
POST /api/v1/notifications/send
```

Sends a push notification to users. Requires admin auth.

#### Headers

```
Authorization: Bearer <admin_jwt_token>
Content-Type: application/json
```

#### Request Body

```json
{
  "title": "Sale Announcement",
  "body": "Flat 20% off on all gold ornaments this weekend!",
  "targetType": "all",
  "targetValue": null
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | string | Yes | Notification title |
| `body` | string | Yes | Notification body text |
| `targetType` | string | Yes | One of: `all`, `topic`, `user` |
| `targetValue` | string | Conditional | Required when `targetType` is `topic` (topic name) or `user` (user ID) |

#### Response (200)

```json
{
  "message": "Notification sent successfully",
  "code": "SUCCESS"
}
```

---

### 4. Notification History (Admin)

```
GET /api/v1/notifications/history
```

Returns paginated history of notifications sent by admins.

#### Headers

```
Authorization: Bearer <admin_jwt_token>
```

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `page` | int | No | `1` | Page number |
| `limit` | int | No | `20` | Items per page |

#### Response (200)

```json
{
  "data": [
    {
      "id": "hist123",
      "title": "Sale Announcement",
      "body": "Flat 20% off on all gold ornaments!",
      "targetType": "all",
      "targetValue": null,
      "sentAt": "2026-06-25T10:30:00.000Z",
      "sentBy": "admin_user_id",
      "recipientCount": 150
    }
  ]
}
```

---

### 5. Update FCM Token

```
POST /api/v1/users/update-fcm-token
```

Registers or refreshes the device's FCM token on the backend. Called automatically when a new token is obtained or refreshed.

#### Request Body

```json
{
  "fcmToken": "fcm_token_string_here"
}
```

---

## FCM Topics

The app subscribes users to FCM topics for broadcast notifications:

| Topic | Used By | Description |
|-------|---------|-------------|
| `all_users` | All users | Receives general broadcast notifications |
| `admin_notifications` | Admin users | Receives admin-specific notifications |

Topics are managed via `NotificationService.subscribeUserTopics()` and `subscribeAdminTopics()`.

---

## Architecture

### Key Files

| File | Purpose |
|------|---------|
| `lib/services/notification_service.dart` | Singleton service handling FCM init, permissions, local notifications, token management, and topic subscriptions |
| `lib/presentation/controllers/notification_controller.dart` | GetX controller managing the user-facing notification list (fetch, mark read, local cache) |
| `lib/presentation/controllers/admin/NotificationManagerController.dart` | GetX controller for admin notification send form and history |
| `lib/data/repositories/notification_repository.dart` | HTTP layer (Dio) for all notification API calls |
| `lib/domain/entities/notification_model.dart` | `NotificationModel` entity with JSON and FCM payload factories |
| `lib/presentation/pages/notifications/notifications_page.dart` | User-facing notifications UI |
| `lib/presentation/pages/admin/notificationManagerScreen.dart` | Admin notification compose and history UI |

### Flow: Receiving a Push Notification

```
FCM Server
  → Firebase Cloud Messaging
    → NotificationService._setupMessageListeners()
      → onMessage (foreground) → _showLocalNotification() → flutter_local_notifications
      → onMessageOpenedApp (background tap) → NotificationController._handleNotificationTap()
      → getInitialMessage (cold start) → NotificationController._handleNotificationTap()
```

### Flow: Sending a Notification (Admin)

```
NotificationManagerScreen → NotificationManagerController.sendNotification()
  → NotificationRepository.sendNotification()
    → POST /api/v1/notifications/send
      → Backend dispatches via FCM to target users/topics
```

### Notification Tap Navigation

When a notification is tapped, the app checks `data['route']` against an allowlist:

```dart
static const Set<String> _allowedRoutes = {
  '/user-order-detail',
  '/admin-order-detail',
  '/gold-rate-detail',
  '/my-orders',
};
```

Only these routes are navigated to; all other notifications are marked read without navigation.

### Local Caching

Notifications are persisted in `SharedPreferences` under key `notifications_list`. On app launch, the cached list is loaded immediately, then the controller fetches fresh data from the backend and merges (deduplicating by `id`).

---

## Error Responses

### 401 Unauthorized

```json
{
  "success": false,
  "error": {
    "code": "INVALID_TOKEN",
    "message": "Invalid token"
  }
}
```

---

## Summary

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/v1/notifications/get-all` | GET | User | Fetch paginated notifications |
| `/api/v1/notifications/action` | PATCH | User | Mark notifications as read |
| `/api/v1/notifications/send` | POST | Admin | Send push notification |
| `/api/v1/notifications/history` | GET | Admin | View sent notification history |
