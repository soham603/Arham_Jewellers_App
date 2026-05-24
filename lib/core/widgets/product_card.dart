import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:shimmer/shimmer.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.compact = false,
    this.onTap,
    this.onAddToCart,
  });

  final ProductModel product;
  final bool compact;

  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  @override
  Widget build(BuildContext context) {
    final cardRadius = context.getScreenWidth(3.5);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            cardRadius,
          ),
          border: Border.all(
            color: const Color(0xFFE7E2DB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [

            Expanded(
              flex: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(cardRadius),
                ),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF8F5F0),
                  padding: EdgeInsets.all(
                    context.getScreenWidth(2),
                  ),
                  child:
                      product.imageUrl != null &&
                              product.imageUrl!
                                  .trim()
                                  .isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl:
                                  product.imageUrl!,
                              fit: BoxFit.contain,
                              width: double.infinity,

                              placeholder:
                                  (
                                    context,
                                    url,
                                  ) {
                                    return Shimmer.fromColors(
                                      baseColor:
                                          const Color(
                                            0xFFE7E2DB,
                                          ),
                                      highlightColor:
                                          const Color(
                                            0xFFF5F1EB,
                                          ),
                                      child:
                                          Container(
                                            color:
                                                Colors
                                                    .white,
                                          ),
                                    );
                                  },

                              errorWidget:
                                  (
                                    context,
                                    url,
                                    error,
                                  ) {
                                    return Center(
                                      child: Icon(
                                        Icons
                                            .image_not_supported_outlined,
                                        color:
                                            Colors
                                                .grey
                                                .shade500,
                                        size:
                                            context
                                                .getScreenWidth(
                                                  8,
                                                ),
                                      ),
                                    );
                                  },
                            )
                          : Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: const Color(
                                  0xFF887A67,
                                ),
                                size:
                                    context
                                        .getScreenWidth(
                                          8,
                                        ),
                              ),
                            ),
                ),
              ),
            ),

            Expanded(
              flex: compact ? 4 : 5,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      context.getScreenWidth(2.8),
                  vertical:
                      context.getScreenHeight(
                        0.6,
                      ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize:
                            context
                                .getScreenWidth(
                                  3.2,
                                ),
                        fontWeight:
                            FontWeight.w700,
                        color:
                            AppColors.textDark,
                      ),
                    ),

                    SizedBox(
                      height:
                          context.getScreenHeight(
                            0.4,
                          ),
                    ),

                    // ==========================
                    // CATEGORY
                    // ==========================

                    if (product.category != null)
                      Container(
                        constraints:
                            BoxConstraints(
                              maxWidth:
                                  double.infinity,
                            ),
                        padding:
                            EdgeInsets.symmetric(
                              horizontal:
                                  context
                                      .getScreenWidth(
                                        2,
                                      ),
                              vertical:
                                  context
                                      .getScreenHeight(
                                        0.2,
                                      ),
                            ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFFF6DD,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                                100,
                              ),
                        ),
                        child: Text(
                          product
                              .category!
                              .name,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style: TextStyle(
                            fontSize:
                                context
                                    .getScreenWidth(
                                      2.5,
                                    ),
                            color:
                                AppColors
                                    .primaryGold,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ),

                    SizedBox(
                      height:
                          context.getScreenHeight(
                            0.3,
                          ),
                    ),

                    // ==========================
                    // TAG
                    // ==========================

                    if (product.tagNo != null)
                      Text(
                        product.tagNo!,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize:
                              context
                                  .getScreenWidth(
                                    2.5,
                                  ),
                          color:
                              AppColors.textMuted,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),

                    const Spacer(),

                    // ==========================
                    // BOTTOM INFO
                    // ==========================

                    Row(
                      children: [
                        if (product.fineWeight !=
                            null)
                          Expanded(
                            child: Text(
                              "Wt ${product.fineWeight}",
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style: TextStyle(
                                fontSize:
                                    context
                                        .getScreenWidth(
                                          2.5,
                                        ),
                                color:
                                    AppColors
                                        .textDark,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ),

                        if (product.touch != null)
                          Expanded(
                            child: Text(
                              "T ${product.touch}",
                              textAlign:
                                  TextAlign.end,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style: TextStyle(
                                fontSize:
                                    context
                                        .getScreenWidth(
                                          2.5,
                                        ),
                                color:
                                    AppColors
                                        .textDark,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ),
                      ],
                    ),

                    if (!compact) ...[
                      SizedBox(
                        height:
                            context
                                .getScreenHeight(
                                  0.7,
                                ),
                      ),

                      SizedBox(
                        width: double.infinity,
                        height:
                            context
                                .getScreenHeight(
                                  4.2,
                                ),
                        child: ElevatedButton(
                          onPressed: onAddToCart,
                          style:
                              ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: AppColors.primaryGold,
                                foregroundColor: AppColors.primaryGold,
                                shadowColor: Colors.transparent,
                                surfaceTintColor: Colors.transparent,
                                disabledBackgroundColor:  AppColors.primaryGold,
                                padding: EdgeInsets.zero,
                                shape:
                                    RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                            12,
                                          ),
                                    ),
                              ),
                          child: Text(
                            "View Product",
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style: TextStyle(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight
                                      .w700,
                              fontSize:
                                  context
                                      .getScreenWidth(
                                        3.25,
                                      ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}