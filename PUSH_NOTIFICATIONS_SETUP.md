# Push Notifications Setup Guide

## What's Implemented

The Flutter client now has full push notification support. Firebase is initialized, FCM tokens are retrieved and sent to the backend on login/register, foreground messages show local notifications, and there's a notification inbox with badge count.

## Next Action Items

### 1. Firebase Project Config

Place these files in the project:

- `android/app/google-services.json` — from Firebase Console > Project Settings > Android app
- `ios/Runner/GoogleService-Info.plist` — from Firebase Console > Project Settings > iOS app

### 2. Backend Endpoint Required

**POST** `/api/v1/auth/update-fcm-token`

Body:
```json
{ "fcmToken": "string" }
```

The client sends this after login and whenever the FCM token refreshes. The backend should store/update the token for the authenticated user.

The login endpoints (`user-login`, `admin-login`) now also send `fcmToken` in the request body — the backend can optionally store it there too.

### 3. Optional: Notification List Endpoint

Currently notifications are stored locally. If you want server-synced notifications, add:

**GET** `/api/v1/notifications`

Response:
```json
{
  "success": true,
  "data": [
    {
      "id": "string",
      "title": "string",
      "body": "string",
      "timestamp": "ISO 8601",
      "isRead": false,
      "data": { "route": "/details", "id": "product_123" }
    }
  ]
}
```

The `data.route` field enables deep-linking from notification taps.

### 4. iOS Setup

Add to `ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>remote-notification</string>
</array>
```

Enable Push Notifications capability in Xcode and upload APNs key to Firebase.

### 5. Android

Done — `POST_NOTIFICATIONS` permission and notification channel are already configured in `AndroidManifest.xml`.
