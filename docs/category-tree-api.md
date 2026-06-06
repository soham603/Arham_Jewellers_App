# Category Tree API

## Endpoint

```
GET /api/v1/category/get-All?tree=true
```

Returns the full category hierarchy in a single response.

## Response Structure

```json
{
  "data": {
    "results": [
      {
        "id": "5051e09e-...",
        "name": "18K",
        "level": 1,
        "children": [
          {
            "id": "ee5b629f-...",
            "name": "FANCY SET",
            "level": 2,
            "children": [
              {
                "id": "ffd4a45c-...",
                "name": "FANCY TIKKI SET",
                "level": 3,
                "children": []
              }
            ]
          }
        ]
      }
    ]
  }
}
```

Level 1: Karat (18K, 20K, 22K) → Level 2: Collection → Level 3: Style

## How the App Uses It

**`CategoryController.fetchCategoryTree()`** — single call on home page init.

1. Fetches tree with `?tree=true`
2. Populates per-karat level-2 lists (`k18Categories`, `k20Categories`, `k22Categories`)
3. Pre-caches level-3 children in `level3Cache[level2.id]`
4. Extracts latest level-3 for search page

**Backward compat:** `fetchAllKaratCategories()` aliases to `fetchCategoryTree()`.

## API Calls Comparison

| Before | After |
|--------|-------|
| 3 × `_getKaratId()` | — |
| 3 × `fetchCategoriesForKarat()` | — |
| N × `_fetchSubcategories()` per tap | — |
| **6+ calls** | **1 call** |

Level-3 data is instant on category tap (pre-cached, no API call).

## Key Methods

| Method | Purpose |
|--------|---------|
| `fetchCategoryTree()` | Fetches full tree, populates all lists + cache |
| `fetchAllKaratCategories()` | Alias for `fetchCategoryTree()` |
| `toggleExpand(cat)` | Shows cached level-3, no API call |
| `selectLevel3Category(cat)` | Loads products for selected style |
