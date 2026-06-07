# Custom Order API

## Base URL

```
https://arham-jewellers-backend.onrender.com
```

---

## Overview

Custom orders follow a different flow than normal product orders. Users create custom orders specifying jewelry requirements (purity, style, marking, weight, etc.), and admins review, approve, reject, or assign them to craftsmen (karigars).

**Key difference:** Normal orders come from the product catalog. Custom orders are user-specified requests that go through a PENDING → ASSIGNED → COMPLETED workflow.

---

## Endpoints

### 1. Create Custom Order (User)

```
POST /api/v1/orders/custom-order
```

Create a new custom order request. Requires user JWT.

#### Headers

```
Authorization: Bearer <user_jwt_token>
Content-Type: multipart/form-data
```

#### Form Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `productId` | string | No | Existing product ID (if customizing a catalog item) |
| `partyCode` | string | Yes | Party code |
| `partyName` | string | Yes | Party name |
| `area` | string | No | Area / locality |
| `contactNumber` | string | Yes | Contact phone number |
| `itemName` | string | Yes | Name of the jewelry item |
| `weight` | string | No | Desired weight |
| `noOfPieces` | string | No | Number of pieces |
| `size` | string | No | Size |
| `lengthBroadness` | string | No | Dimensions (length × breadth) |
| `productDescription` | string | No | Free-text description |
| `purity` | string | Yes | Gold purity (e.g. `"18K"`, `"22K"`) |
| `style` | string | Yes | Style preference |
| `marking` | string | Yes | Marking / hallmark preference |
| `referenceImages` | file[] | No | Reference images (max 4) |

#### Response (201)

```json
{
  "success": true,
  "data": {
    "orderId": "uuid",
    "referenceImagesUploaded": 3,
    "message": "Custom order placed successfully. Our team will review and contact you shortly."
  }
}
```

#### Notes

- Max 4 images allowed
- If order creation fails, uploaded images are auto-deleted
- Default status: `PENDING`

---

### 2. Modify Custom Order (User)

```
PATCH /api/v1/orders/custom-order/:orderId
```

Update an existing custom order. Only `PENDING` orders can be modified. Requires user JWT.

#### Headers

```
Authorization: Bearer <user_jwt_token>
Content-Type: multipart/form-data
```

#### Form Fields (all optional — update any subset)

| Field | Type | Description |
|-------|------|-------------|
| `partyCode` | string | Party code |
| `partyName` | string | Party name |
| `area` | string | Area |
| `contactNumber` | string | Contact number |
| `itemName` | string | Item name |
| `weight` | string | Weight |
| `noOfPieces` | string | Pieces |
| `size` | string | Size |
| `lengthBroadness` | string | Dimensions |
| `productDescription` | string | Description |
| `purity` | string | Purity |
| `style` | string | Style |
| `marking` | string | Marking |
| `images` | file[] | New images (max 4) |
| `removeOldImages` | bool | If `true`, delete existing images before uploading new ones |

#### Image Logic

| Scenario | Behavior |
|----------|----------|
| `removeOldImages = true` + new images | Delete all existing, upload new |
| `removeOldImages = false` + new images | Keep old, append new (max total 4) |
| No images sent | Text fields only |

#### Response (200)

```json
{
  "success": true,
  "data": {
    "orderId": "uuid",
    "updatedImages": 2,
    "message": "Custom order updated successfully"
  }
}
```

#### Rules

- Only `PENDING` orders can be modified
- Max total images = 4
- Failed upload rolls back already uploaded images

---

### 3. Delete Custom Order (User)

```
DELETE /api/v1/orders/custom-order/:orderId
```

Delete a custom order. Requires user JWT.

#### Headers

```
Authorization: Bearer <user_jwt_token>
```

#### Behavior

1. Validate order exists
2. Check user permission
3. Delete all images from storage
4. Delete order + order items

#### Response (200)

```json
{
  "success": true,
  "message": "Custom order deleted successfully"
}
```

#### Rules

- Cannot delete `COMPLETED` orders (recommended)
- Always cleans up images from storage

---

### 4. Get All Orders (Admin — Normal + Custom)

```
GET /api/v1/admin-order/get-AllOrders
```

Unified endpoint for fetching all orders (both normal and custom). Supports filtering by `orderType`. Requires admin JWT.

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `page` | int | No | `1` | Page number |
| `limit` | int | No | `10` | Items per page |
| `status` | string | No | `"PENDING"` | Filter by status |
| `orderType` | string | No | `"all"` | `"all"`, `"normal"`, or `"custom"` |
| `userPhoneNumber` | string | No | — | Filter by user phone (with `+91` prefix) |

#### Response (200)

```json
{
  "success": true,
  "data": {
    "page": 1,
    "totalPages": 5,
    "results": [
      {
        "id": "uuid",
        "status": "PENDING",
        "adminMessage": null,
        "totalAmount": null,
        "createdAt": "2026-06-07T10:00:00.000Z",
        "updatedAt": "2026-06-07T10:00:00.000Z",
        "isCustom": true,
        "user": {
          "id": "uuid",
          "name": "John Doe",
          "phoneNumber": "+918097137041",
          "companyName": "Acme Corp",
          "city": "Mumbai"
        },
        "orderItems": [
          {
            "id": "uuid",
            "orderId": "uuid",
            "productId": "uuid",
            "quantity": 1,
            "price": 0,
            "stockNote": "",
            "isRejected": false,
            "product": {
              "id": "uuid",
              "name": "Custom Gold Ring",
              "imageUrl": "https://..."
            }
          }
        ]
      }
    ]
  }
}
```

#### Notes

- Use `orderType=custom` to show only custom orders
- Use `orderType=normal` to show only normal orders
- Use `orderType=all` (or omit) to show both
- Custom orders are identified by `isCustom: true` in the response

---

### 5. Admin Action on Custom Order

```
POST /api/v1/admin-order/custom-order/action
```

Perform actions on custom orders (reject, approve+assign, complete). Requires admin JWT.

#### Headers

```
Authorization: Bearer <admin_jwt_token>
Content-Type: application/json
```

#### Request Body

```json
{
  "orderId": "uuid",
  "action": "APPROVE_AND_ASSIGN",
  "adminMessage": "Optional note",
  "assignedKarigarId": "uuid",
  "talkedToStaffName": "Rahul",
  "assignAdminNotes": "Handle with care",
  "deliveryDate": "2026-06-10",
  "completeAdminNotes": "Finished successfully"
}
```

#### Action Types

| Action | Description | Required Fields |
|--------|-------------|-----------------|
| `REJECT` | Reject the order | `adminMessage` (optional) |
| `APPROVE_AND_ASSIGN` | Approve and assign to karigar | `assignedKarigarId` |
| `COMPLETE` | Mark order as completed | `deliveryDate`, `completeAdminNotes` (optional) |

#### Action Flows

**REJECT** (only `PENDING` orders)

```json
{
  "orderId": "uuid",
  "action": "REJECT",
  "adminMessage": "Not feasible"
}
```

Result: status → `REJECTED`, order closed.

**APPROVE_AND_ASSIGN** (only `PENDING` orders)

```json
{
  "orderId": "uuid",
  "action": "APPROVE_AND_ASSIGN",
  "assignedKarigarId": "uuid",
  "talkedToStaffName": "Ravi",
  "assignAdminNotes": "Priority order"
}
```

Result: status → `ASSIGNED`, karigar assigned, order approved automatically.

**COMPLETE** (only `ASSIGNED` orders)

```json
{
  "orderId": "uuid",
  "action": "COMPLETE",
  "deliveryDate": "2026-06-10",
  "completeAdminNotes": "Delivered successfully"
}
```

Result: status → `COMPLETED`, delivery date stored, order closed.

#### Response (200)

```json
{
  "success": true,
  "message": "Custom order updated successfully"
}
```

#### Invalid State Transitions

| From | To | Allowed |
|------|----|---------|
| PENDING | REJECTED | Yes |
| PENDING | ASSIGNED | Yes |
| ASSIGNED | COMPLETED | Yes |
| PENDING | COMPLETED | No |
| REJECTED | anything | No |
| COMPLETED | anything | No |

---

### 6. Get All Craftsmen (Admin)

```
GET /api/v1/craftsman/get-All
```

Fetch all available craftsmen (karigars) for assignment. Requires admin JWT.

#### Headers

```
Authorization: Bearer <admin_jwt_token>
```

#### Response (200)

```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "Ramesh",
      "phoneNumber": "9999999999",
      "accountName": "Gold Works",
      "areaName": "Mumbai"
    }
  ]
}
```

#### Notes

- Currently returns empty list (no craftsmen in DB)
- Used by admin when performing `APPROVE_AND_ASSIGN` action

---

## Custom Order Workflow

```
User creates order
       ↓
    PENDING
       ↓
  ┌────┴────┐
  ↓         ↓
REJECT    APPROVE_AND_ASSIGN
           ↓
        ASSIGNED
           ↓
        COMPLETED
```

---

## Data Model

### CustomOrderModel Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string (UUID) | Order ID |
| `productId` | string? | Linked product ID (if from catalog) |
| `partyCode` | string | Party code |
| `partyName` | string | Party name |
| `area` | string? | Area |
| `contactNumber` | string | Contact phone |
| `itemName` | string | Jewelry item name |
| `weight` | string? | Desired weight |
| `noOfPieces` | string? | Number of pieces |
| `size` | string? | Size |
| `lengthBroadness` | string? | Dimensions |
| `productDescription` | string? | Description |
| `purity` | string | Gold purity |
| `style` | string | Style |
| `marking` | string | Marking |
| `referenceImages` | string[] | Image URLs |
| `status` | string | Order status |
| `adminMessage` | string? | Admin's message |
| `assignedKarigarId` | string? | Assigned karigar UUID |
| `assignedKarigarName` | string? | Karigar name |
| `talkedToStaffName` | string? | Staff contact name |
| `assignAdminNotes` | string? | Assignment notes |
| `completeAdminNotes` | string? | Completion notes |
| `deliveryDate` | string? | Expected delivery date |
| `isCustomOrder` | bool | Always `true` |
| `createdAt` | datetime | Creation timestamp |
| `updatedAt` | datetime | Last update timestamp |

### Status Values

| Status | Description |
|--------|-------------|
| `PENDING` | Awaiting admin review |
| `REJECTED` | Rejected by admin |
| `ASSIGNED` | Approved and assigned to karigar |
| `COMPLETED` | Order fulfilled |

---

## User-Side Order List

Custom orders appear in the same order list as normal orders via:

```
GET /api/v1/products/get-userAllOrders
```

Both normal and custom orders are returned together. Custom orders can be identified by the presence of custom-order-specific fields (e.g. `itemName`, `purity`, `style`, `marking`).

---

## Frontend Implementation

### Controllers

| Controller | Purpose |
|------------|---------|
| `CustomOrderController` | Create, modify, delete custom orders (user-side) |
| `AdminOrderController` | Fetch all orders, filter by `orderType`, perform custom order actions (admin-side) |
| `UserOrderController` | Fetch user's orders (includes both normal and custom) |

### Pages

| Page | Purpose |
|------|---------|
| `customise_order_page.dart` | User creates/modifies a custom order |
| `customOrderDetailPage.dart` | User views/deletes a custom order |
| `adminCustomOrdersPage.dart` | Admin lists custom orders (filtered from unified endpoint) |
| `adminCustomOrderDetailPage.dart` | Admin views custom order details and performs actions |
| `my_orders_page.dart` | User sees all orders (normal + custom) in one list |

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

### 400 Bad Request

```json
{
  "success": false,
  "message": "Only PENDING orders can be modified"
}
```

### 404 Not Found

```json
{
  "success": false,
  "message": "Order not found"
}
```
