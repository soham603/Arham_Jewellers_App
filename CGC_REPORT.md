# CGC Report

_Generated: 2026-06-11 10:52 UTC_

_Scoped to repository: `/home/parthhimself/arham-ratnesh-app/Arham_Jewellers_App`_


## God Nodes — Highest Fan-In
_These nodes are called from many places. High fan-in increases risk: a change here affects every caller._

| Kind | Name | File | In-degree |
| --- | --- | --- | --- |
| Function | SessionManager | utils/SessionManager.dart | 10 |
| Class | SessionManager | utils/SessionManager.dart | 9 |
| Function | fetchRequests | admin/AdminUserController.dart | 8 |
| Function | fetchUsers | admin/AdminUserManagementController.dart | 7 |
| Function | _downloadAndCompressImage | services/share_service.dart | 6 |
| Function | fetchOrders | admin/AdminOrderController.dart | 6 |
| Function | fetchHistory | admin/GoldRateController.dart | 6 |
| Function | _showSnack | admin/carouselManagerScreen.dart | 6 |
| Class | LogoWidget | widgets/logo_widget.dart | 6 |
| Function | _saveCart | controllers/cart_controller.dart | 5 |
| Function | _runSearch | controllers/searchProductController.dart | 5 |
| Function | _updateUnreadCount | controllers/notification_controller.dart | 5 |
| Function | fetchRequests | admin/HandsetChangeController.dart | 5 |
| Function | _loadLogoBytes | services/share_service.dart | 5 |
| Class | AnimatedTextField | widgets/animated_text_field.dart | 4 |


## Most Complex Functions
_Cyclomatic complexity > 10 is a refactoring candidate._

| Function | File | Cyclomatic Complexity |
| --- | --- | --- |
| _buildOrderDetailsPdfInIsolate | services/share_service.dart | 17 |
| _buildPdfInIsolate | services/share_service.dart | 14 |
| loadLatestProducts | controllers/carousel_controller.dart | 11 |
| _buildCartEnquiryPdfInIsolate | services/share_service.dart | 11 |
| buildRow | services/share_service.dart | 9 |
| fuzzyMatchScore | utils/fuzzy_match.dart | 8 |
| _levenshtein | utils/fuzzy_match.dart | 8 |
| buildRow | services/share_service.dart | 7 |
| application | Runner/AppDelegate.swift | 6 |
| deleteCarousel | controllers/carousel_controller.dart | 6 |
| _compressBytes | admin/AdminCategoryController.dart | 6 |
| getDeviceName | services/deviceIdService.dart | 5 |
| fuzzyFilter | utils/fuzzy_match.dart | 4 |
| restoreCarousel | controllers/carousel_controller.dart | 4 |
| _confirmDelete | admin/categoryManagerScreen.dart | 4 |


## Cross-Module Connections
_Calls that cross package boundaries — review for unexpected coupling._

| Caller | Caller File | Callee | Callee File | Confidence |
| --- | --- | --- | --- | --- |
| build | orders/order_success_page.dart | UserOrderController | controllers/userOrderController.dart | EXTRACTED |
| build | product/chain_listing_page.dart | JewelleryDivider | widgets/custom_divider.dart | EXTRACTED |
| initState | notifications/notifications_page.dart | NotificationController | controllers/notification_controller.dart | EXTRACTED |
| build | notifications/notifications_page.dart | ResponsiveWrapper | widgets/responsive_wrapper.dart | EXTRACTED |
| initState | admin/adminCustomOrderDetailPage.dart | AdminOrderController | admin/AdminOrderController.dart | EXTRACTED |
| initState | admin/adminCustomOrdersPage.dart | AdminOrderController | admin/AdminOrderController.dart | EXTRACTED |
| build | pages/main_shell_view.dart | AppBottomNav | widgets/app_bottom_nav.dart | EXTRACTED |
| _showProductsPerPageDialog | share/share_page.dart | ShareProductsPerPageSheet | widgets/share_products_per_page_sheet.dart | EXTRACTED |
| build | auth/forgot_password_page.dart | AnimatedTextField | widgets/animated_text_field.dart | EXTRACTED |
| build | auth/forgot_password_page.dart | LogoWidget | widgets/logo_widget.dart | EXTRACTED |
| Dependencies.dart | services/Dependencies.dart | BaseHttpService | restServices/apiService.dart | EXTRACTED |
| Dependencies.dart | services/Dependencies.dart | BaseHttpService | restServices/apiService.dart | EXTRACTED |
| build | splash/splash_page.dart | LogoWidget | widgets/logo_widget.dart | EXTRACTED |
| initState | wishlist/wishlist_page.dart | WishlistController | controllers/wishlist_controller.dart | EXTRACTED |
| build | wishlist/wishlist_page.dart | ProductCard | widgets/product_card.dart | EXTRACTED |
| initState | admin/ancillary_editor_screen.dart | AncillaryController | admin/AncillaryController.dart | EXTRACTED |
| main | lib/main.dart | NotificationService | services/notification_service.dart | EXTRACTED |
| main | lib/main.dart | GoldRateController | admin/GoldRateController.dart | EXTRACTED |
| _sendTokenToBackend | controllers/notification_controller.dart | SessionManager | utils/SessionManager.dart | EXTRACTED |
| _sendTokenToBackend | controllers/notification_controller.dart | SessionManager | utils/SessionManager.dart | EXTRACTED |


## Potential Dead Code
_Functions with zero callers (not guaranteed dead — may be entry points or called via reflection)._

| Function | File |
| --- | --- |
| registerPlugins | dartpad/web_plugin_registrant.dart |
| registerWith | plugins/GeneratedPluginRegistrant.java |
| __lldb_init_module | ephemeral/flutter_lldb_helper.py |
| handle_new_rx_page | ephemeral/flutter_lldb_helper.py |
| testExample | RunnerTests/RunnerTests.swift |
| build | app/app.dart |
| dependencies | routes/app_pages.dart |
| ancillaryGetPage | constants/ApiUrlConstants.dart |
| ancillaryUpdatePage | constants/ApiUrlConstants.dart |
| customOrderDelete | constants/ApiUrlConstants.dart |
| customOrderModify | constants/ApiUrlConstants.dart |
| _buildCartEnquiryPdfInIsolate | services/share_service.dart |
| _buildOrderDetailsPdfInIsolate | services/share_service.dart |
| _buildPdfInIsolate | services/share_service.dart |
| _infoChipCompact | services/share_service.dart |
| buildFilterInfo | services/share_service.dart |
| buildRow | services/share_service.dart |
| buildRow | services/share_service.dart |
| fetchProductCount | services/share_service.dart |
| saveCartEnquiryPdfToDownloads | services/share_service.dart |


## Suggested Cypher Queries
_Copy these into `execute_cypher_query` to explore further._

### Callers of a specific function
```cypher
MATCH (caller)-[:CALLS]->(fn:Function {name: 'yourFunctionName'})
RETURN caller.name, caller.path LIMIT 20
```

### Class hierarchy for a specific class
```cypher
MATCH path = (c:Class {name: 'YourClass'})-[:INHERITS*]->(parent)
RETURN [n IN nodes(path) | n.name] AS hierarchy
```

### Most-injected Spring beans
```cypher
MATCH ()-[:INJECTS]->(bean:Class)
RETURN bean.name, count(*) AS injection_count
ORDER BY injection_count DESC LIMIT 10
```

### All external library dependencies
```cypher
MATCH (m:MavenModule)-[:USES_LIBRARY]->(lib:ExternalLibrary)
RETURN m.artifact_id, lib.group_id, lib.artifact_id, lib.version
ORDER BY lib.artifact_id
```

### CALLS edges with low confidence (potential mis-resolutions)
```cypher
MATCH (a)-[c:CALLS]->(b)
WHERE c.confidence_label = 'AMBIGUOUS'
RETURN a.name, b.name, c.resolution_tier, a.path LIMIT 20
```
