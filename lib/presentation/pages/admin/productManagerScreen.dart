import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/adminProductController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';


class AdminProductScreen extends StatefulWidget {
  const AdminProductScreen({super.key});

  @override
  State<AdminProductScreen> createState() => _AdminProductScreenState();
}

class _AdminProductScreenState extends State<AdminProductScreen> {
  final AdminProductController ctrl = Get.put(AdminProductController());
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchTextCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (ctrl.isSearchMode) {
        ctrl.loadMoreSearch();
      } else {
        ctrl.loadMoreProducts();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchTextCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorPalette.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.colorPalette.backgroundColor,
        elevation: 0,
        title: Text(
          'Product Manager',
          style: TextStyle(
            fontSize: context.getScreenWidth(5),
            fontWeight: FontWeight.w700,
            color: context.colorPalette.textColor,
          ),
        ),
        actions: [
          Obx(() => Padding(
                padding: EdgeInsets.only(right: context.getScreenWidth(4)),
                child: Center(
                  child: Text(
                    '${ctrl.total} total',
                    style: TextStyle(
                      fontSize: context.getScreenWidth(3.2),
                      color: context.colorPalette.subTitleColor,
                    ),
                  ),
                ),
              )),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(context),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              final list = ctrl.displayList;
              final state =
                  ctrl.isSearchMode ? ctrl.searchState : ctrl.state;

              if (state == CurrentAppState.LOADING && list.isEmpty) {
                return _buildShimmerGrid(context);
              }

              if (state == CurrentAppState.ERROR && list.isEmpty) {
                return _buildError(context);
              }

              if (state == CurrentAppState.SUCCESS && list.isEmpty) {
                return _buildEmpty(context);
              }

              return RefreshIndicator(
                onRefresh: ctrl.refreshProducts,
                color: context.colorPalette.primaryColor,
                child: GridView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(context.getScreenWidth(3)),
                  itemCount: list.length + 1,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: context.getScreenWidth(2.5),
                    crossAxisSpacing: context.getScreenWidth(2.5),
                    childAspectRatio: 0.68,
                  ),
                  itemBuilder: (context, index) {
                    if (index == list.length) {
                      return _buildGridFooter(context);
                    }
                    return _buildAdminProductCard(context, list[index]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Search + Filter bar ───────────────────────────────────────────────────
  Widget _buildSearchAndFilters(BuildContext context) {
    return Container(
      color: context.colorPalette.backgroundColor,
      padding: EdgeInsets.fromLTRB(
        context.getScreenWidth(4),
        context.getScreenHeight(1.2),
        context.getScreenWidth(4),
        context.getScreenHeight(1),
      ),
      child: Column(
        children: [
          // Search bar
          Container(
            height: context.getScreenHeight(5.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCFC7BC)),
              color: const Color(0xFFF4F1EC),
            ),
            child: TextField(
              controller: _searchTextCtrl,
              style: TextStyle(
                fontSize: context.getScreenWidth(3.8),
                color: context.colorPalette.textColor,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: context.getScreenHeight(1.5),
                ),
                hintText: 'Search by name, tag...',
                hintStyle: TextStyle(
                  fontSize: context.getScreenWidth(3.5),
                  color: const Color(0xFFA29A90),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: context.getScreenWidth(4.5),
                  color: const Color(0xFF8D847A),
                ),
                suffixIcon: _searchTextCtrl.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchTextCtrl.clear();
                          setState(() {});
                          ctrl.exitSearch();
                        },
                        child: Icon(
                          Icons.close,
                          size: context.getScreenWidth(4),
                          color: const Color(0xFF8D847A),
                        ),
                      )
                    : null,
              ),
              onChanged: (v) {
                setState(() {});
                ctrl.setSearch(v);
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  ctrl.runSearch();
                });
              },
              onSubmitted: (_) => ctrl.runSearch(),
            ),
          ),
          SizedBox(height: context.getScreenHeight(1)),

          // Filter chips row
          Row(
            children: [
              Expanded(child: _buildKaratDropdown(context)),
              SizedBox(width: context.getScreenWidth(2)),
              Obx(() => _buildInactiveToggle(context)),
              SizedBox(width: context.getScreenWidth(2)),
              _buildClearBtn(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKaratDropdown(BuildContext context) {
    return Obx(() => Container(
          height: context.getScreenHeight(5),
          padding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(3)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCFC7BC)),
            color: const Color(0xFFF4F1EC),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: ctrl.filterKarat,
              isExpanded: true,
              hint: Text(
                'All Karats',
                style: TextStyle(
                  fontSize: context.getScreenWidth(3.3),
                  color: const Color(0xFFA29A90),
                ),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: context.getScreenWidth(4.5),
                color: const Color(0xFF8D847A),
              ),
              style: TextStyle(
                fontSize: context.getScreenWidth(3.5),
                color: context.colorPalette.textColor,
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Karats',
                      style: TextStyle(fontSize: context.getScreenWidth(3.3))),
                ),
                ...['18K', '20K', '22K'].map((k) => DropdownMenuItem<String?>(
                      value: k,
                      child: Text(k,
                          style: TextStyle(
                              fontSize: context.getScreenWidth(3.3))),
                    )),
              ],
              onChanged: ctrl.setKaratFilter,
            ),
          ),
        ));
  }

  Widget _buildInactiveToggle(BuildContext context) {
    final active = ctrl.showInactive;
    return GestureDetector(
      onTap: () => ctrl.setShowInactive(!active),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.getScreenWidth(2.5),
          vertical: context.getScreenHeight(1.2),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: active
              ? Colors.orange.withOpacity(0.12)
              : const Color(0xFFF4F1EC),
          border: Border.all(
            color: active
                ? Colors.orange.withOpacity(0.4)
                : const Color(0xFFCFC7BC),
          ),
        ),
        child: Icon(
          active ? Icons.visibility : Icons.visibility_off_outlined,
          size: context.getScreenWidth(4.5),
          color: active ? Colors.orange : const Color(0xFF8D847A),
        ),
      ),
    );
  }

  Widget _buildClearBtn(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _searchTextCtrl.clear();
        setState(() {});
        ctrl.clearFilters();
      },
      child: Container(
        padding: EdgeInsets.all(context.getScreenWidth(2.5)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCFC7BC)),
          color: const Color(0xFFF4F1EC),
        ),
        child: Icon(
          Icons.refresh_rounded,
          size: context.getScreenWidth(4.5),
          color: const Color(0xFF8D847A),
        ),
      ),
    );
  }

  Widget _buildAdminProductCard(BuildContext context, ProductModel product) {
    return Obx(() {
      final isLoading = ctrl.actionLoadingId == product.id;
      final isInactive = !product.isActive;

      return GestureDetector(
        onTap: () => _showEditSheet(context, product),
        child: Opacity(
          opacity: isInactive ? 0.55 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: context.colorPalette.boxColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isInactive
                    ? Colors.orange.withOpacity(0.3)
                    : context.colorPalette.boxColor,
              ),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // image
                    Expanded(
                      flex: 3,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14)),
                        child: product.imageUrl != null &&
                                product.imageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: product.imageUrl!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: context.colorPalette.shimmerBaseColor,
                                ),
                                errorWidget: (_, __, ___) =>
                                    _noImagePlaceholder(context),
                              )
                            : _noImagePlaceholder(context),
                      ),
                    ),
                    // info
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding:
                            EdgeInsets.all(context.getScreenWidth(2.5)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: context.getScreenWidth(3.2),
                                fontWeight: FontWeight.w600,
                                color: context.colorPalette.textColor,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                if (product.karat != null)
                                  _karatBadge(context, product.karat!),
                                if (product.tagNo != null)
                                  Text(
                                    '#${product.tagNo}',
                                    style: TextStyle(
                                      fontSize: context.getScreenWidth(2.8),
                                      color:
                                          context.colorPalette.subTitleColor,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // inactive badge
                if (isInactive)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.getScreenWidth(2),
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'INACTIVE',
                        style: TextStyle(
                          fontSize: context.getScreenWidth(2.2),
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                // edit icon top-right
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: EdgeInsets.all(context.getScreenWidth(1.5)),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      size: context.getScreenWidth(4),
                      color: Colors.white,
                    ),
                  ),
                ),

                // loading overlay
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _noImagePlaceholder(BuildContext context) {
    return Container(
      color: context.colorPalette.boxColor,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: context.getScreenWidth(8),
          color: context.colorPalette.subTitleColor,
        ),
      ),
    );
  }

  Widget _karatBadge(BuildContext context, String karat) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.getScreenWidth(2),
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
      ),
      child: Text(
        karat,
        style: TextStyle(
          fontSize: context.getScreenWidth(2.5),
          color: const Color(0xFF8B6914),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ── Edit Bottom Sheet ─────────────────────────────────────────────────────
  void _showEditSheet(BuildContext context, ProductModel product) {
    final nameCtrl = TextEditingController(text: product.name);
    String? selectedKarat = product.karat;
    bool isActive = product.isActive;
    bool deleteImg = false;
    ctrl.clearPickedImage();

    // raw data editing: flatten to string key-value pairs for simple UI
    final rawEntries = <MapEntry<TextEditingController, TextEditingController>>[];
    if (product.rawData is Map) {
      (product.rawData as Map).forEach((k, v) {
        rawEntries.add(MapEntry(
          TextEditingController(text: k.toString()),
          TextEditingController(text: v.toString()),
        ));
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return DraggableScrollableSheet(
            initialChildSize: 0.88,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder: (_, scrollCtrl) => Container(
              decoration: BoxDecoration(
                color: context.colorPalette.backgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                controller: scrollCtrl,
                padding: EdgeInsets.fromLTRB(
                  context.getScreenWidth(5),
                  0,
                  context.getScreenWidth(5),
                  context.getScreenHeight(4),
                ),
                children: [
                  // drag handle
                  Center(
                    child: Container(
                      margin: EdgeInsets.symmetric(
                          vertical: context.getScreenHeight(1.5)),
                      width: context.getScreenWidth(10),
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.colorPalette.boxColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Product',
                              style: TextStyle(
                                fontSize: context.getScreenWidth(5),
                                fontWeight: FontWeight.w700,
                                color: context.colorPalette.textColor,
                              ),
                            ),
                            Text(
                              product.tagNo != null
                                  ? '#${product.tagNo}'
                                  : product.id.substring(0, 8),
                              style: TextStyle(
                                fontSize: context.getScreenWidth(3.2),
                                color: context.colorPalette.subTitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // active toggle
                      GestureDetector(
                        onTap: () => setSheet(() => isActive = !isActive),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.getScreenWidth(3),
                            vertical: context.getScreenHeight(0.8),
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: isActive
                                ? Colors.green.withOpacity(0.12)
                                : Colors.orange.withOpacity(0.12),
                            border: Border.all(
                              color: isActive
                                  ? Colors.green.withOpacity(0.4)
                                  : Colors.orange.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: context.getScreenWidth(3.2),
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.getScreenHeight(2.5)),

                  // ── Image ─────────────────────────────────────────────
                  _editLabel(context, 'Image'),
                  SizedBox(height: context.getScreenHeight(1)),
                  Obx(() {
                    final picked = ctrl.pickedImage;
                    return GestureDetector(
                      onTap: () async {
                        await ctrl.pickImage();
                        setSheet(() {});
                      },
                      child: Container(
                        height: context.getScreenHeight(18),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: picked != null
                                ? context.colorPalette.primaryColor
                                : context.colorPalette.boxColor,
                            width: picked != null ? 2 : 1,
                          ),
                          color: context.colorPalette.boxColor.withOpacity(0.3),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: picked != null
                              ? Stack(children: [
                                  Image.file(picked,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        ctrl.clearPickedImage();
                                        setSheet(() {});
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.close,
                                            size: context.getScreenWidth(4),
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ])
                              : (product.imageUrl != null &&
                                          product.imageUrl!.isNotEmpty &&
                                          !deleteImg
                                      ? Stack(children: [
                                          CachedNetworkImage(
                                            imageUrl: product.imageUrl!,
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                          Container(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: () => setSheet(
                                                  () => deleteImg = true),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      context.getScreenWidth(3),
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red
                                                      .withOpacity(0.85),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'Remove image',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: context
                                                        .getScreenWidth(3),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.edit,
                                                    color: Colors.white,
                                                    size:
                                                        context.getScreenWidth(
                                                            5)),
                                                Text('Tap to change',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: context
                                                            .getScreenWidth(3))),
                                              ],
                                            ),
                                          ),
                                        ])
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_photo_alternate_outlined,
                                              size: context.getScreenWidth(8),
                                              color: context
                                                  .colorPalette.subTitleColor,
                                            ),
                                            SizedBox(
                                                height:
                                                    context.getScreenHeight(
                                                        0.5)),
                                            Text(
                                              deleteImg
                                                  ? 'Image will be removed — tap to add new'
                                                  : 'Tap to add image',
                                              style: TextStyle(
                                                fontSize:
                                                    context.getScreenWidth(3.2),
                                                color: context
                                                    .colorPalette.subTitleColor,
                                              ),
                                            ),
                                          ],
                                        )),
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: context.getScreenHeight(2)),

                  // ── Name ──────────────────────────────────────────────
                  _editLabel(context, 'Name'),
                  SizedBox(height: context.getScreenHeight(0.8)),
                  _textField(context, nameCtrl, 'Product name'),
                  SizedBox(height: context.getScreenHeight(2)),

                  // ── Karat ─────────────────────────────────────────────
                  _editLabel(context, 'Karat'),
                  SizedBox(height: context.getScreenHeight(0.8)),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.getScreenWidth(4)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: context.colorPalette.boxColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: selectedKarat,
                        isExpanded: true,
                        hint: Text('Select karat',
                            style: TextStyle(
                                fontSize: context.getScreenWidth(3.8),
                                color: context.colorPalette.subTitleColor)),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('None',
                                style: TextStyle(
                                    fontSize: context.getScreenWidth(3.8),
                                    color: context.colorPalette.textColor)),
                          ),
                          ...['18K', '20K', '22K'].map((k) =>
                              DropdownMenuItem<String?>(
                                value: k,
                                child: Text(k,
                                    style: TextStyle(
                                        fontSize: context.getScreenWidth(3.8),
                                        color: context.colorPalette.textColor)),
                              )),
                        ],
                        onChanged: (v) => setSheet(() => selectedKarat = v),
                      ),
                    ),
                  ),
                  SizedBox(height: context.getScreenHeight(2)),

                  // ── Raw Data ──────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _editLabel(context, 'Raw Data'),
                      GestureDetector(
                        onTap: () => setSheet(() {
                          rawEntries.add(MapEntry(
                            TextEditingController(),
                            TextEditingController(),
                          ));
                        }),
                        child: Icon(
                          Icons.add_circle_outline,
                          size: context.getScreenWidth(5),
                          color: context.colorPalette.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.getScreenHeight(1)),
                  ...rawEntries.asMap().entries.map((e) {
                    final i = e.key;
                    final entry = e.value;
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: context.getScreenHeight(1)),
                      child: Row(
                        children: [
                          Expanded(
                            child: _textField(
                                context, entry.key, 'Key'),
                          ),
                          SizedBox(width: context.getScreenWidth(2)),
                          Expanded(
                            child: _textField(
                                context, entry.value, 'Value'),
                          ),
                          SizedBox(width: context.getScreenWidth(2)),
                          GestureDetector(
                            onTap: () =>
                                setSheet(() => rawEntries.removeAt(i)),
                            child: Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                              size: context.getScreenWidth(5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: context.getScreenHeight(3)),

                  // ── Save ──────────────────────────────────────────────
                  Obx(() {
                    final loading = ctrl.actionLoadingId == product.id;
                    return SizedBox(
                      width: double.infinity,
                      height: context.getScreenHeight(6.5),
                      child: ElevatedButton(
                        onPressed: loading
                            ? null
                            : () async {
                                // build rawDataPatch from entries
                                final patch = <String, dynamic>{};
                                for (final e in rawEntries) {
                                  final k = e.key.text.trim();
                                  final v = e.value.text.trim();
                                  if (k.isNotEmpty) patch[k] = v;
                                }

                                final success = await ctrl.updateProduct(
                                  id: product.id,
                                  name: nameCtrl.text.trim().isNotEmpty
                                      ? nameCtrl.text.trim()
                                      : null,
                                  karat: selectedKarat,
                                  isActive: isActive,
                                  rawDataPatch:
                                      patch.isNotEmpty ? patch : null,
                                  deleteCurrentImage: deleteImg,
                                );

                                if (success && context.mounted) {
                                  Get.back();
                                  Get.snackbar(
                                    'Updated',
                                    '${product.name} updated successfully',
                                    backgroundColor:
                                        Colors.green.withOpacity(0.9),
                                    colorText: Colors.white,
                                    duration: const Duration(seconds: 2),
                                  );
                                } else if (!success && context.mounted) {
                                  Get.snackbar(
                                    'Failed',
                                    'Could not update product. Try again.',
                                    backgroundColor:
                                        Colors.red.withOpacity(0.9),
                                    colorText: Colors.white,
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              context.colorPalette.primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: context.getScreenWidth(4.2),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _editLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: context.getScreenWidth(3.8),
        fontWeight: FontWeight.w600,
        color: context.colorPalette.textColor,
      ),
    );
  }

  Widget _textField(
    BuildContext context,
    TextEditingController ctrl,
    String hint,
  ) {
    return TextField(
      controller: ctrl,
      style: TextStyle(
        fontSize: context.getScreenWidth(3.8),
        color: context.colorPalette.textColor,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: context.getScreenWidth(3.5),
          color: context.colorPalette.subTitleColor,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.getScreenWidth(4),
          vertical: context.getScreenHeight(1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.colorPalette.boxColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.colorPalette.boxColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: context.colorPalette.primaryColor),
        ),
      ),
    );
  }

  // ── Shimmer grid ──────────────────────────────────────────────────────────
  Widget _buildShimmerGrid(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(context.getScreenWidth(3)),
      itemCount: 10,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: context.getScreenWidth(2.5),
        crossAxisSpacing: context.getScreenWidth(2.5),
        childAspectRatio: 0.68,
      ),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: context.colorPalette.shimmerBaseColor,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildGridFooter(BuildContext context) {
    final loading = ctrl.isSearchMode
        ? ctrl.searchState == CurrentAppState.LOADING
        : ctrl.state == CurrentAppState.LOADING;
    final noMore = ctrl.isSearchMode ? !ctrl.searchHasMore : !ctrl.hasMore;

    if (loading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.getScreenWidth(4)),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.colorPalette.primaryColor,
          ),
        ),
      );
    }

    if (noMore) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.getScreenWidth(4)),
          child: Text(
            'All products loaded',
            style: TextStyle(
              fontSize: context.getScreenWidth(3.2),
              color: context.colorPalette.subTitleColor,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: context.getScreenWidth(12), color: Colors.red),
          SizedBox(height: context.getScreenHeight(1.5)),
          Text('Failed to load products',
              style: TextStyle(
                  fontSize: context.getScreenWidth(4),
                  color: context.colorPalette.textColor)),
          SizedBox(height: context.getScreenHeight(2)),
          ElevatedButton(
            onPressed: ctrl.refreshProducts,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorPalette.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
                const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: context.getScreenWidth(12),
              color: context.colorPalette.subTitleColor),
          SizedBox(height: context.getScreenHeight(1.5)),
          Text('No products found',
              style: TextStyle(
                  fontSize: context.getScreenWidth(4),
                  color: context.colorPalette.subTitleColor)),
        ],
      ),
    );
  }
}