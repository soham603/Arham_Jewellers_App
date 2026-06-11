# Products API

## Base URL

```
https://arham-jewellers-backend.onrender.com
```

---

## Endpoints

### 1. Get All Products (Paginated)

```
GET /api/v1/products/get-all
```

Returns a paginated list of products. Supports category and stock filtering.

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `page` | int | No | `1` | Page number (1-indexed) |
| `limit` | int | No | `10` | Items per page |
| `showReverse` | bool | No | `false` | If `true`, reverse sort order (newest first) |
| `categoryId` | string | No | — | Filter by level-3 category UUID |
| `showAll` | bool | No | `false` | If `true`, include inactive products (requires admin auth) |

#### Response (200)

```json
{
  "success": true,
  "message": "Products fetched successfully",
  "data": {
    "paginated": true,
    "totalCount": 39167,
    "currentPage": 1,
    "totalPages": 13056,
    "data": [
      {
        "id": "958334b7-...",
        "tagId": "13142171756001",
        "tagNo": "84MS-977",
        "name": "84 MANGALSUTRA",
        "nameSlug": "84-mangalsutra",
        "imageUrl": "https://pub-b3d833affd70422a9e7369888f85ab52.r2.dev/ArhamInventory/stockImages/....jpg",
        "karat": "18K",
        "isActive": true,
        "createdAt": "2026-06-06T08:12:29.483Z",
        "rawData": { ... },
        "category": {
          "id": "71f47343-...",
          "name": "DOUBLE LINE MS",
          "nameSlug": "double-line-ms",
          "level": 3,
          "parentId": "0ef34479-..."
        }
      }
    ]
  }
}
```

#### Notes

- `totalCount` is total across all pages; `totalPages = totalCount / limit` (ceiling).
- When `categoryId` is provided, only products in that category (and its descendants) are returned.
- `showAll=true` is admin-only; public users only see `isActive: true` products.

---

### 2. Search Products

```
GET /api/v1/products/search
```

Search products by text, barcode, tagId, karat, or category. Returns paginated or single results.

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `search` | string | No | — | Free-text search (matches name, tagNo, etc.) |
| `barcode` | string | No | — | Exact barcode match (returns single product) |
| `tagId` | string | No | — | Exact tagId match (returns single product) |
| `karat` | string | No | — | Filter by karat (e.g. `"18K"`, `"22K"`) |
| `categoryId` | string | No | — | Filter by level-3 category UUID |
| `page` | int | No | `1` | Page number |
| `limit` | int | No | `10` | Items per page |
| `showAll` | bool | No | `false` | Include inactive products (admin auth) |

#### Response (200) — Text Search

```json
{
  "success": true,
  "message": "Products fetched successfully",
  "data": {
    "paginated": true,
    "totalCount": 8865,
    "currentPage": 1,
    "totalPages": 2955,
    "data": [
      {
        "id": "9b3a5bcc-...",
        "tagId": "13141120831391",
        "tagNo": "84GR-2500",
        "name": "6-84 GENTS RINGS COLLECTION",
        "nameSlug": "6-84-gents-rings-collection",
        "imageUrl": "https://...",
        "karat": "18K",
        "isActive": true,
        "createdAt": "2026-06-06T08:12:29.483Z",
        "category": {
          "id": "46031250-...",
          "name": "DEPPA GR",
          "nameSlug": "deppa-gr",
          "level": 3,
          "parentId": "159335c6-..."
        }
      }
    ]
  }
}
```

#### Response (200) — Barcode Search

When `barcode` is provided, `data.data` is a **single object** (not an array):

```json
{
  "success": true,
  "message": "Products fetched successfully",
  "data": {
    "paginated": false,
    "totalCount": 1,
    "data": {
      "id": "958334b7-...",
      "tagId": "13142171756001",
      "tagNo": "84MS-977",
      "name": "84 MANGALSUTRA",
      "imageUrl": "https://...",
      "karat": "18K",
      "isActive": true,
      "rawData": { ... },
      "category": { ... }
    }
  }
}
```

#### Response (200) — TagId Search

When `tagId` is provided, `data.data` is a **single object** (not an array):

```json
{
  "success": true,
  "message": "Products fetched successfully",
  "data": {
    "paginated": false,
    "totalCount": 1,
    "data": {
      "id": "63d2ae53-...",
      "tagId": "11354143108707",
      "tagNo": "92BX-4594",
      "name": "92 BOX PACKING",
      "imageUrl": "https://...",
      "karat": null,
      "isActive": true,
      "rawData": { ... },
      "category": { ... }
    }
  }
}
```

**⚠️ Important:** Barcode and tagId searches return `data.data` as a **single object**, not an array. Text/category search returns `data.data` as an **array**. The frontend must handle both shapes.

---

### 3. Update Product (Admin)

```
PATCH /api/v1/products/update/:id
```

Update a product's details. Requires admin JWT.

#### Headers

```
Authorization: Bearer <admin_jwt_token>
Content-Type: multipart/form-data
```

#### Form Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Product name |
| `karat` | string | Karat value (e.g. `"18K"`) |
| `categoryId` | string | Level-3 category UUID |
| `isActive` | bool | Whether product is active |
| `rawDataPatch` | string (JSON) | Partial update to rawData fields |
| `image` | file | New product image |
| `deleteImage` | bool | Remove existing image |

---

## Product Object Schema

### Top-Level Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string (UUID) | Unique product identifier |
| `tagId` | string | Numeric tag ID from inventory system |
| `tagNo` | string | Human-readable tag number (e.g. `"84MS-977"`) |
| `name` | string | Product name |
| `nameSlug` | string | URL-safe slug of name |
| `imageUrl` | string? | R2-hosted image URL (can be `null`) |
| `karat` | string | Karat value: `"18K"`, `"20K"`, `"22K"` |
| `isActive` | bool | Whether product is active/visible |
| `createdAt` | string (ISO 8601) | Creation timestamp |
| `rawData` | object | Full inventory stock data (see below) |
| `category` | object? | Nested category (see below) |

### Category Object

| Field | Type | Description |
|-------|------|-------------|
| `id` | string (UUID) | Category UUID |
| `name` | string | Category name (level-3 style name) |
| `nameSlug` | string | URL-safe slug |
| `level` | int | Always `3` (leaf level) |
| `parentId` | string (UUID) | Parent category UUID (level-2 collection) |

### rawData Fields (Key Subset)

The `rawData` object contains 100+ fields from the inventory system. The most useful for frontend:

#### Weights

| Field | Type | Description |
|-------|------|-------------|
| `GrossWt` | double? | Gross weight in grams |
| `NetWt` | double? | Net weight (Gross - Less) |
| `FineWt` | double? | Fine weight (Net × Touch/100) |
| `LessWt` | double? | Less weight (wastage) |
| `OthWeight` | double? | Other weight |
| `PackingWt` | double? | Packing weight |
| `WithPackingWeight` | double? | Total weight with packing |
| `KarigarNetWt` | double? | Karigar net weight |
| `KarigarFineWt` | double? | Karigar fine weight |

#### Pricing / Purity

| Field | Type | Description |
|-------|------|-------------|
| `Touch` | double | Purity percentage (e.g. `83.3` for 18K, `91.6` for 22K) |
| `SalesTouch` | int | Sales purity (e.g. `84` for 18K, `92` for 22K) |
| `SalesFineWt` | double | Sales fine weight |
| `Rate` | double? | Metal rate |
| `SalesWastagePrc` | double | Sales wastage percentage (always `6`) |
| `WastagePrc` | double | Cost wastage percentage |
| `MRP` | double | Maximum retail price |
| `TaxPrc` | double? | Tax percentage (usually `3`) |
| `TaxAmt` | double? | Tax amount |

#### Stock / Inventory

| Field | Type | Description |
|-------|------|-------------|
| `IsStock` | int | Stock status: `1` = in stock, `0` = out of stock |
| `Barcode` | string | Barcode number |
| `CounterName` | string? | Counter location (e.g. `"MAIN STOCK"`) |
| `VoucherNo` | string? | Voucher number |
| `VoucherDate` | string? | Voucher date (`.NET` format) |

#### Product Details

| Field | Type | Description |
|-------|------|-------------|
| `ItemName` | string | Item name (matches top-level `name`) |
| `SubItemName` | string? | Sub-item name (style variant) |
| `DesignName` | string? | Design name |
| `DesignCode` | string? | Design code |
| `GroupName` | string? | Group name (e.g. `"84 GOLD ORNAMENT"`) |
| `MetalType` | string? | `"G"` = Gold, `"S"` = Silver |
| `Size1` | string? | Size (e.g. `"S-12"`, `"SHORT"`) |
| `GenderName` | string? | Gender target (e.g. `"-"`) |
| `HSNCode` | string? | HSN code for GST |
| `Pcs` | int? | Number of pieces |
| `ColPcs` | int? | Color stone pieces |
| `DiamondPcs` | int? | Diamond pieces |
| `DiamondWeight` | double? | Diamond weight |
| `DiamondAmount` | double? | Diamond amount |
| `Diamonds` | array | Diamond details array |

#### IDs / References

| Field | Type | Description |
|-------|------|-------------|
| `ItemID` | int | Inventory item ID |
| `ItemSubID` | int | Sub-item ID |
| `GroupItemID` | int | Group item ID |
| `ItemGroupID` | int | Item group ID |
| `DesignCodeID` | int | Design code ID |
| `BranchID` | int? | Branch ID |
| `CompanyID` | int? | Company ID |
| `CounterID` | int? | Counter ID |
| `FinyearID` | int | Financial year ID |

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

### 403 Forbidden (admin-only endpoints)

```json
{
  "success": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "Admin access required"
  }
}
```

---

## Pagination Summary

| Endpoint | Behavior |
|----------|----------|
| `GET /get-all` | Returns `data.data` as **array**, `totalCount`/`totalPages` for pagination |
| `GET /search?search=` | Returns `data.data` as **array**, paginated |
| `GET /search?barcode=` | Returns `data.data` as **single object**, `paginated: false` |
| `GET /search?tagId=` | Returns `data.data` as **single object**, `paginated: false` |
