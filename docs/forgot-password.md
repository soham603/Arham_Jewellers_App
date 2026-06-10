
# 1. CHANGE PASSWORD API

## Route

```http
PUT /auth/change-password
```

## Auth

```text
Bearer Token required (USER / ADMIN)
```

---

## Request Body

```json
{
  "oldPassword": "123456",
  "newPassword": "newPass123"
}
```

---

## Success Response

```json
{
  "success": true,
  "message": "Password changed successfully",
  "data": null
}
```

---

## Errors

### Wrong old password

```json
{
  "success": false,
  "message": "Old password is incorrect"
}
```

### Validation error

```json
{
  "success": false,
  "message": "\"newPassword\" length must be at least 6 characters long"
}
```

---

## CURL

```bash
curl -X PUT "/auth/change-password" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "oldPassword": "123456",
    "newPassword": "newPass123"
  }'
```

---

#  2. FORGOT PASSWORD API

## Route

```http
POST /auth/forgot-password
```

---

##  Request Body

```json
{
  "phoneNumber": "+919876543210"
}
```

---

##  Response (always safe)

```json
{
  "success": true,
  "message": "If an account exists, a reset request will be processed shortly."
}
```

---

## CURL

```bash
curl -X POST "/auth/forgot-password" \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+919876543210"
  }'
```

---

#  3. ADMIN RESET PASSWORD API

## Route

```http
PUT /admin/admin-reset-password
```

##  Role

```text
SUPERADMIN only
```

---

##  Request Body

```json
{
  "userId": "uuid",
  "newPassword": "newPass123"
}
```

---

## CURL

```bash
curl -X PUT "/admin/admin-reset-password" \
  -H "Authorization: Bearer SUPERADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "USER_UUID",
    "newPassword": "newPass123"
  }'
```

---

#  4. USER ACTIVATION API

## Route

```http
PATCH /update-user-activation
```

##  Roles

```text
ADMIN / SUPERADMIN
```

---

## Request Body

```json
{
  "userId": "uuid",
  "action": "ACTIVE"
}
```

or

```json
{
  "userId": "uuid",
  "action": "DEACTIVATED"
}
```

---

## CURL

### Activate user

```bash
curl -X PATCH "/update-user-activation" \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "USER_UUID",
    "action": "ACTIVE"
  }'
```

---

### Deactivate user

```bash
curl -X PATCH "/update-user-activation" \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "USER_UUID",
    "action": "DEACTIVATED"
  }'
```

---

#  5. ACCESS REQUEST APPROVE/REJECT

## Route

```http
POST /admin/handle-access
```

---

## Approve

```json
{
  "requestId": "uuid",
  "action": "APPROVED",
  "approvedTillDate": "2026-12-31T00:00:00.000Z",
  "retailUser": true
}
```

---

## Reject

```json
{
  "requestId": "uuid",
  "action": "REJECTED",
  "rejectionReason": "Invalid documents"
}
```

---

## CURL (APPROVE)

```bash
curl -X POST "/admin/handle-access" \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "requestId": "REQUEST_UUID",
    "action": "APPROVED",
    "approvedTillDate": "2026-12-31T00:00:00.000Z",
    "retailUser": true
  }'
```

---

## CURL (REJECT)

```bash
curl -X POST "/admin/handle-access" \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "requestId": "REQUEST_UUID",
    "action": "REJECTED",
    "rejectionReason": "Invalid documents"
  }'
```

---

#  6. ADMIN / USERS LIST API (you built earlier)

## Route

```http
GET /admin/users
```

---

##  Query params

```
?page=1&limit=10&name=soham&email=test@gmail.com&phoneNumber=+91
```

---

## CURL

```bash
curl -X GET "/admin/users?page=1&limit=10" \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

---

#  FINAL DEVELOPER NOTES (IMPORTANT)

## Role hierarchy you defined

```
SUPERADMIN → sees ADMIN + USER
ADMIN → sees USER only
USER → sees self only
```

---

## System rules implemented

* no user enumeration
* full token reset on deactivation
* access approval strict validation
* forgot password = request-based system (not direct reset)
* admin notifications via push

