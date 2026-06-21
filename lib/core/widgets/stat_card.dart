import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class StatData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const StatData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class StatCard extends StatelessWidget {
  final StatData data;

  const StatCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.getResponsiveSize(3.5)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: context.getResponsiveSize(5.2),
                    color: AppColors.textDark,
                  ),
                ),
              ),
              SizedBox(width: context.getResponsiveSize(2)),
              Container(
                width: context.getResponsiveSize(8),
                height: context.getResponsiveSize(8),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  data.icon,
                  color: data.color,
                  size: context.getResponsiveSize(4),
                ),
              ),
            ],
          ),
          SizedBox(height: context.heightPercent(0.5)),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: context.getResponsiveSize(3),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
