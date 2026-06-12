# Push Notifications Setup Guide

## Architecture Overview

The notification system has two tiers:

| Tier | Source | Display | Firebase Required? |
|------|--------|---------|-------------------|
| **System notifications** | FCM push from backend | Android/iOS notification shade | Yes |
| **In-app notifications** | Client-side triggers (order status, gold rate) | Notification inbox screen | No |

The app builds and runs without `google-services.json`. FCM features are disabled gracefully; local/in-app notifications continue to work.

---

## Client-Side Implementation

### Key Files

| File | Purpose |
|------|---------|
| `lib/services/notification_service.dart` | Singleton service — Firebase init, FCM token, topic subscriptions, system notification display |
| `lib/presentation/controllers/notification_controller.dart` | GetX controller — in-app notification list, unread badge, deep-link navigation |
| `lib/presentation/controllers/admin/NotificationManagerController.dart` | Admin composer — send notifications via backend API, fetch sent history |
| `lib/data/repositories/notification_repository.dart` | API layer — Dio calls to backend notification endpoints |
| `lib/domain/entities/notification_model.dart` | Data model — `NotificationModel` with JSON serialization |
| `lib/presentation/pages/admin/notificationManagerScreen.dart` | Admin UI — compose form + sent history with infinite scroll |
| `lib/presentation/pages/notifications/notifications_page.dart` | User UI — notification inbox with read/unread state |

### Graceful Degradation

`NotificationService.init()` is split into two independent blocks:

1. **Local notification setup** (always runs) — initializes `flutter_local_notifications`, creates the Android notification channel, loads the persisted ID counter.
2. **Firebase / FCM setup** (may fail) — initializes Firebase, obtains FCM token, subscribes to topics, sets up message listeners.

If Firebase is not configured (missing `google-services.json`), the catch block logs a warning and the app continues. The `isInitialized` flag stays `false` for FCM, but `showSystemNotification()` and all in-app notification features remain operational.

---

## Backend API Contracts

### 1. Update FCM Token

**POST** `/api/v1/auth/update-fcm-token`

Called by the client after login and whenever the FCM token refreshes.

**Auth:** Bearer token (optional — silently skipped if user is not logged in)

**Request Body:**
```json
{
  "fcmToken": "string"
}
```

**Success Response:** `200 OK`
```json
{
  "success": true,
  "message": "FCM token updated"
}
```

**Error Response:** `4xx / 5xx`
```json
{
  "success": false,
  "error": {
    "message": "string"
  }
}
```

**Client behavior:** Retries once after 5 seconds on failure. Logs error via `Logger.error`.

---

### 2. Send Notification (Admin)

**POST** `/api/v1/notifications/send`

Used by the admin notification composer screen.

**Auth:** Bearer token (required — `requiresAuth: true`)

**Request Body:**
```json
{
  "title": "string (required, non-empty)",
  "body": "string (required, non-empty)",
  "targetType": "all | topic | user (required)",
  "targetValue": "string (optional — required when targetType is 'topic' or 'user')"
}
```

**Success Response:** `200 OK`
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "Notification sent successfully",
  "data": {
    "id": "string",
    "recipientCount": 123
  }
}
```

**Error Response:** `4xx / 5xx`
```json
{
  "success": false,
  "code": "ERROR",
  "error": {
    "message": "string"
  }
}
```

**Client behavior:** Shows success/error toast via `ToastUtils`. On `DioException`, extracts message from `response.data.error.message` or `response.data.message`. If backend is unreachable, shows a toast with the network error message.

---

### 3. Notification History

**GET** `/api/v1/notifications/history`

Returns paginated list of previously sent notifications.

**Auth:** Bearer token (required — `requiresAuth: true`)

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `page` | int | 1 | Page number (1-indexed) |
| `limit` | int | 20 | Items per page (max 20) |

**Success Response:** `200 OK`
```json
{
  "success": true,
  "code": "SUCCESS",
  "data": {
    "notifications": [
      {
        "id": "string",
        "title": "string",
        "body": "string",
        "targetType": "all | topic | user",
        "targetValue": "string | null",
        "sentAt": "ISO 8601 timestamp",
        "sentBy": "string (admin username)",
        "recipientCount": 123
      }
    ],
    "total": 50,
    "page": 1,
    "limit": 20
  }
}
```

**Alternative response format** (backend may also return a flat list):
```json
{
  "success": true,
  "code": "SUCCESS",
  "data": [
    { ... }
  ]
}
```

**Client behavior:** Supports infinite scroll pagination. Shows shimmer loading skeleton on initial load. Shows error message text if the endpoint is unreachable. Parses both `camelCase` and `snake_case` keys from the backend.

---

## FCM Topics

Topics are used for broadcast-style push notifications from the backend.

| Topic | Purpose | Subscribed By | When |
|-------|---------|--------------|------|
| `all_users` | Broadcast to all registered users (promotions, general announcements) | `NotificationService().subscribeUserTopics()` | User login + session restore (non-admin) |
| `admin_notifications` | Broadcast to all admin users (new orders, system alerts) | `NotificationService().subscribeAdminTopics()` | Admin login + session restore |
| Both topics | Cleanup on sign-out | `NotificationService().unsubscribeAllTopics()` | Logout (user or admin) |

**Backend usage:** To send a push notification to all users, the backend should send an FCM message to the `all_users` topic. The client automatically subscribes/unsubscribes based on the user's role.

---

## Backend Event-Driven Push (Recommended)

The backend should trigger FCM push notifications for the following events:

### Order Status Changes

When an order status changes, send a push to the order's user FCM token:

```
Topic/Token:  user-specific FCM token
Title:        "Order Status Update"
Body:         "Your order #ORD-123 has been approved"
Data: {
  "route": "/user-order-detail",
  "id": "order_123",
  "orderId": "ORD-123",
  "status": "approved"
}
```

**Status → message mapping:**
| Status | Body |
|--------|------|
| `approved` | "Your order #{orderId} has been approved" |
| `rejected` | "Your order #{orderId} has been rejected" |
| `completed` | "Your order #{orderId} has been completed" |
| `dispatched` | "Your order #{orderId} has been dispatched" |

### Gold Rate Updates

When the gold rate is updated, broadcast to all users:

```
Topic:       all_users
Title:       "Gold Rate Updated"
Body:        "Gold rate is now ₹6,250/g (change: +₹50)"
Data: {
  "route": "/gold-rate-detail",
  "rate": "6250",
  "change": "+50"
}
```

### Custom Order Status Changes

Similar to standard orders, send to the user's FCM token:

```
Topic/Token:  user-specific FCM token
Title:        "Custom Order Update"
Body:         "Your custom order has been approved"
Data: {
  "route": "/user-order-detail",
  "id": "custom_order_123"
}
```

### New Order Alert (Admin)

When a new order is placed, notify admins:

```
Topic:       admin_notifications
Title:       "New Order Received"
Body:        "Order #ORD-123 from John Doe — ₹15,000"
Data: {
  "route": "/admin-order-detail",
  "id": "order_123"
}
```

---

## Firebase Project Setup

### Android

1. In Firebase Console, create a project and register an Android app with package name `com.arhamjewellers.ratnesh_gold_app`
2. Download `google-services.json` and place it at `android/app/google-services.json`
3. Uncomment the Google Services plugin in `android/app/build.gradle.kts`:
   ```kotlin
   id("com.google.gms.google-services") // uncomment this line
   ```
4. The `POST_NOTIFICATIONS` permission and notification channel (`arham_jewellers_high_importance`) are already configured in `AndroidManifest.xml`

### iOS

1. Register an iOS app in Firebase Console
2. Download `GoogleService-Info.plist` and place it at `ios/Runner/GoogleService-Info.plist`
3. Add to `ios/Runner/Info.plist`:
   ```xml
   <key>UIBackgroundModes</key>
   <array>
     <string>fetch</string>
     <string>remote-notification</string>
   </array>
   ```
4. Enable Push Notifications capability in Xcode
5. Upload APNs authentication key to Firebase Console

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `firebase_core` | ^3.12.1 | Firebase initialization |
| `firebase_messaging` | ^15.2.5 | FCM token, message listeners, topic subscriptions |
| `flutter_local_notifications` | ^18.0.1 | System-level notification display |

---

## App Behavior Without Firebase

| Feature | Works Without Firebase? | Notes |
|---------|------------------------|-------|
| App launch / navigation | Yes | |
| Local notification list (in-app) | Yes | Stored in SharedPreferences |
| In-app notification triggers (order, gold rate) | Yes | `addLocalNotification()` is client-side |
| System notification shade | No | Requires FCM for push delivery |
| FCM token operations | No | Skipped gracefully, logged as info |
| Topic subscriptions | No | Skipped gracefully, logged as info |
| Admin notification composer | Depends on backend | Shows error toast if backend is unreachable |
| Notification history | Depends on backend | Shows error state in UI |
