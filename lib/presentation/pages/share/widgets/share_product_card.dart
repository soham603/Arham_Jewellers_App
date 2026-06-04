import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/ratnesh_fallback.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:shimmer/shimmer.dart';

class ShareProductCard extends StatelessWidget {
  const ShareProductCard({
    super.key,
    required this.product,
    required this.isSelected,
    required this.onTap,
  });

  final ProductModel product;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayName = _cleanText(product.name) ?? 'Untitled';
    final imageUrl = _cleanText(product.displayImageUrl);
    final categoryName = _cleanText(product.category?.name);
    final fineWeight = _formatValue(product.fineWeight);
    final touchData = _parseTouch(product.touch);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : const Color(0xFFE7E2DB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primaryGold.withOpacity(0.15)
                  : Colors.black.withOpacity(0.06),
              blurRadius: isSelected ? 12 : 8,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(13)),
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: const Color(0xFFE8E3DB),
                              highlightColor: const Color(0xFFF7F3ED),
                              child: const DecoratedBox(
                                decoration:
                                    BoxDecoration(color: Colors.white),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                const RatneshFallback.m(),
                          )
                        : const RatneshFallback.m(),
                  ),
                  // Selection checkmark
                  Positioned(
                    top: 8,
                    right: 8,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.primaryGold
                            : Colors.black.withOpacity(0.3),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (categoryName != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
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
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      height: 1.3,
                    ),
                  ),
                  if (fineWeight != null || touchData != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: _WeightInfo(
                        fineWeight: fineWeight,
                        touchData: touchData,
                      ),
                    ),
                ],
              ),
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

  static _TouchData? _parseTouch(String? touch) {
    if (touch == null || touch.isEmpty) return null;
    final match = RegExp(r'([\d.]+)\s*\((\d+)\s*K\)').firstMatch(touch);
    if (match != null) {
      return _TouchData(
        karat: match.group(2),
        touchValue: match.group(1),
      );
    }
    return _TouchData(karat: null, touchValue: touch);
  }
}

class _TouchData {
  final String? karat;
  final String? touchValue;
  const _TouchData({this.karat, this.touchValue});
}

class _WeightInfo extends StatelessWidget {
  const _WeightInfo({
    required this.fineWeight,
    required this.touchData,
  });

  final String? fineWeight;
  final _TouchData? touchData;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 9,
      color: AppColors.textDark.withOpacity(0.7),
      fontWeight: FontWeight.w500,
      height: 1.3,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (fineWeight != null)
          Text('Wt: ${fineWeight}g', style: style, maxLines: 1),
        if (touchData != null) ...[
          if (fineWeight != null) const SizedBox(height: 1),
          _PurityRow(data: touchData!, style: style),
        ],
      ],
    );
  }
}

class _PurityRow extends StatelessWidget {
  const _PurityRow({required this.data, required this.style});

  final _TouchData data;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final hasKarat = data.karat != null;
    final hasTouch = data.touchValue != null;
    final spans = <TextSpan>[];

    if (hasKarat) {
      spans.add(TextSpan(text: '${data.karat}K Gold', style: style));
    }
    if (hasKarat && hasTouch) {
      spans.add(TextSpan(
          text: '  •  ',
          style: style.copyWith(
              color: AppColors.textDark.withOpacity(0.3))));
    }
    if (hasTouch) {
      spans.add(TextSpan(text: '${data.touchValue} Touch', style: style));
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
