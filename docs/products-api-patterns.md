# Products API — Frontend Patterns & Observations

## API Response Inconsistencies

### 1. `data.data` Shape Inconsistency

The biggest gotcha — the `data.data` field changes shape depending on the endpoint:

| Endpoint | `data.data` type | `paginated` |
|----------|-----------------|-------------|
| `GET /get-all` | `Array<Product>` | `true` |
| `GET /search?search=` | `Array<Product>` | `true` |
| `GET /search?barcode=` | `Object` (single product) | `false` |

**Frontend must normalize this.** The `SearchProductController` already handles it at `lib/presentation/controllers/searchProductController.dart` — barcode results are treated differently.

### 2. `karat` Is Always Populated (Not Null)

Despite initial suspicion, `karat` is **always present** in the API response — values seen: `"18K"`, `"20K"`. No nulls found in sample of 20 products.

The `karat` field on the top-level product is the **source of truth** for karat filtering. The `rawData.Touch` / `rawData.SalesTouch` fields are the underlying purity values.

**Frontend usage:** `SearchProductController` uses `product.karat` for karat filter. This is reliable.

### 3. `imageUrl` Can Be Null

7 out of 20 products had `imageUrl: null`. These products only have the fallback `rawData.imageurl` (relative path like `/Images/TagImage/....jpg`).

**Frontend already handles this** via `ProductModel.displayImageUrl` getter:
```dart
String? get displayImageUrl => imageUrl ?? stockImage;
```
Where `stockImage` returns `rawData['imageurl']`.

**⚠️ Risk:** The `rawData.imageurl` is a relative path (no base URL). The frontend likely needs to prepend the backend base URL or an asset CDN prefix. Verify this is working correctly.

### 4. `rawData` Is Massive (100+ Fields)

The `rawData` object dumps the entire inventory record — 100+ keys, most of which are null or zero. Only ~20 fields are commonly used by the frontend.

**Frontend pattern:** `ProductModel` exposes computed getters (`grossWeight`, `netWeight`, `fineWeight`, `touch`, `barcode`, etc.) that safely extract from `rawData` with null checks. This is the correct approach — never access `rawData` directly in widgets.

### 5. Weight Fields Are Often Null

From the sample:
- `GrossWt` — sometimes null (1 product out of 20)
- `NetWt` — sometimes null
- `FineWt` — usually present when `Touch` is present
- `PackingWt` — often null or zero
- `WithPackingWeight` — often null

**Frontend pattern:** `SearchProductController` sorts by `(grossWeight ?? fineWeight ?? 0)` — handles null gracefully.

### 6. `IsStock` Is an Integer, Not Boolean

`IsStock` is `1` (Ready Stock / Available) or `0` (Order Item / Not in stock), not a boolean. The frontend uses `product.rawData?['IsStock'] == 1` for stock checks.

### 7. `SalesWastagePrc` Is Always `6`

Across all sampled products, `SalesWastagePrc` is consistently `6`. This appears to be a fixed sales-side wastage rate.

### 8. `rawData.VoucherDate` Uses .NET Date Format

Dates in `rawData` use `/Date(1779388200000)/` format (epoch millis wrapped in .NET convention). The frontend does not currently parse these.

### 9. `tagNo` Contains Karat Prefix

The `tagNo` field encodes karat in its prefix:
- `84MS-977` → `84` prefix = 18K (84% purity)
- `84GR-2500` → `84` = 18K
- `92LR-xxxx` would be 22K

**Frontend already uses this** as a fallback in `ProductModel.touch` getter — extracts first 2 chars of `tagNo` to resolve purity.

### 10. `category` Object Only Returns Level-3

The nested `category` in the product response only contains the leaf-level (level-3) category. Level-1 (karat) and level-2 (collection) must be resolved via the category tree API.

**Frontend pattern:** `CategoryController.fetchCategoryTree()` pre-caches the full tree. Product → category mapping is done client-side using `category.parentId` to find level-2, then level-1.

---

## Useful rawData Fields for Frontend

### Must-Use (displayed in UI)

| Getter | rawData Key | Used In |
|--------|------------|---------|
| `grossWeight` | `GrossWt` | Product card, details, sort |
| `netWeight` | `NetWt` | Product details, ribbon |
| `fineWeight` | `FineWt` | Product card, share card |
| `touch` / `salesTouch` | `SalesTouch` / `Touch` | Product card, purity badge |
| `barcode` | `Barcode` | Barcode scanner |
| `size` | `Size1` | Product details spec |
| `hsnCode` | `HSNCode` | Product details (if needed) |

### Available But Underused

| rawData Key | Description | Potential Use |
|------------|-------------|---------------|
| `Pcs` | Piece count | Show "Set of X" badge |
| `DiamondPcs` / `DiamondWeight` | Diamond info | Diamond product badges |
| `MetalType` | G/S | Gold vs Silver filter |
| `GenderName` | Gender | Gender filter |
| `StyleName` | Style | Style badge |
| `OthItem` / `IsOther` | Other item info | "Includes X" label |
| `ColPcs` / `ColWeight` | Color stone info | Stone details |
| `WithPackingWeight` | Total with packing | Shipping weight |

---

## Frontend Code References

| File | Purpose |
|------|---------|
| `lib/domain/entities/productModel.dart` | Product model with rawData getters |
| `lib/presentation/controllers/searchProductController.dart` | Customer product fetching, filtering, sorting |
| `lib/presentation/controllers/admin/adminProductController.dart` | Admin CRUD operations |
| `lib/presentation/controllers/share_controller.dart` | Share flow product listing |
| `lib/presentation/pages/product/product_listing_page.dart` | Product grid/list UI |
| `lib/presentation/pages/product/product_details_page.dart` | Product detail view |
| `lib/core/widgets/product_card.dart` | Reusable product card |
