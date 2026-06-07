import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/ratnesh_fallback.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:shimmer/shimmer.dart';

class ProductListTile extends StatelessWidget {
  const ProductListTile({
    super.key,
    required this.product,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final displayName = _cleanText(product.name) ?? 'Untitled Product';
    final imageUrl = _cleanText(product.displayImageUrl);
    final categoryName = _cleanText(product.category?.name);
    final tagNo = _cleanText(product.tagNo);
    final fineWeight = _formatValue(product.fineWeight);
    final grossWeight = _formatValue(product.grossWeight);
    final touchData = _parseTouch(product.touch);
    final size = _cleanText(product.size);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : const Color(0xFFE7E2DB),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primaryGold.withOpacity(0.15)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 10 : 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: const Color(0xFFE8E3DB),
                              highlightColor: const Color(0xFFF7F3ED),
                              child: const DecoratedBox(
                                decoration: BoxDecoration(color: Colors.white),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                const RatneshFallback.s(),
                          )
                        : const RatneshFallback.s(),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tagNo != null)
                    Text(
                      tagNo,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textDark.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (categoryName != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 2, top: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF6DD),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(100),
                          bottomRight: Radius.circular(100),
                        ),
                      ),
                      child: Text(
                        categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Text(
                    displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (grossWeight != null)
                        _InfoChip(label: 'Wt: ${grossWeight}g'),
                      if (fineWeight != null && fineWeight != grossWeight)
                        _InfoChip(label: 'Fine: ${fineWeight}g'),
                      if (touchData != null) _InfoChip(label: touchData),
                      if (size != null) _InfoChip(label: 'Size: $size'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textDark.withOpacity(0.3),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  static String? _cleanText(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null ||
        cleaned.isEmpty ||
        cleaned.toLowerCase() == 'null') {
      return null;
    }
    return cleaned;
  }

  static String? _formatValue(Object? value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty || raw.toLowerCase() == 'null') return null;
    final parsed = num.tryParse(raw);
    if (parsed == null) return raw;
    if (parsed == parsed.roundToDouble()) return parsed.toInt().toString();
    return parsed
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static String? _parseTouch(String? touch) {
    if (touch == null || touch.isEmpty) return null;
    final match = RegExp(r'([\d.]+)\s*\((\d+)\s*K\)').firstMatch(touch);
    if (match != null) {
      return '${match.group(2)}K \u2022 ${match.group(1)} Touch';
    }
    return touch;
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3EF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: AppColors.textDark.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
