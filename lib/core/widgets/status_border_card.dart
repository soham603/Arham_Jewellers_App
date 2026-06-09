import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

// ── Status Info Model ────────────────────────────────────────────────────────

class StatusInfo {
  final String label;
  final Color color;
  final Color bgColor;

  const StatusInfo({
    required this.label,
    required this.color,
    required this.bgColor,
  });
}

// ── Status Resolver ──────────────────────────────────────────────────────────

StatusInfo getStatusInfo(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return const StatusInfo(
        label: 'Pending',
        color: Color(0xFFF5A623),
        bgColor: Color(0xFFFFF4E0),
      );
    case 'confirmed':
      return const StatusInfo(
        label: 'Confirmed',
        color: Color(0xFF2D8C56),
        bgColor: Color(0xFFE6F7EE),
      );
    case 'processing':
      return const StatusInfo(
        label: 'Processing',
        color: Color(0xFFA57A36),
        bgColor: Color(0xFFF9F3E8),
      );
    case 'approved':
      return const StatusInfo(
        label: 'Approved',
        color: Color(0xFF2D8C56),
        bgColor: Color(0xFFE6F7EE),
      );
    case 'assigned':
      return const StatusInfo(
        label: 'Assigned',
        color: Color(0xFF3B82F6),
        bgColor: Color(0xFFEFF6FF),
      );
    case 'completed':
    case 'delivered':
      return StatusInfo(
        label: 'Delivered',
        color: AppColors.primaryGold,
        bgColor: const Color(0xFFF9F3E8),
      );
    case 'cancelled':
      return const StatusInfo(
        label: 'Cancelled',
        color: Color(0xFFDC2626),
        bgColor: Color(0xFFFEE2E2),
      );
    case 'rejected':
      return const StatusInfo(
        label: 'Rejected',
        color: Color(0xFFDC2626),
        bgColor: Color(0xFFFEE2E2),
      );
    default:
      return StatusInfo(
        label: status.isNotEmpty
            ? '${status[0].toUpperCase()}${status.substring(1)}'
            : 'Unknown',
        color: AppColors.textMuted,
        bgColor: AppColors.tileBg,
      );
  }
}

// ── Status Badge Widget ──────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: context.getResponsiveSize(3),
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Status Border Card ───────────────────────────────────────────────────────

class StatusBorderCard extends StatelessWidget {
  final String status;
  final VoidCallback? onTap;
  final Widget child;
  final bool showBadge;
  final String? badgeLabel;

  const StatusBorderCard({
    super.key,
    required this.status,
    required this.child,
    this.onTap,
    this.showBadge = false,
    this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = getStatusInfo(status);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE7DED2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 4,
                width: double.infinity,
                color: statusInfo.color,
              ),
              if (showBadge)
                Padding(
                  padding: EdgeInsets.only(
                    top: context.getScreenWidth(3),
                    right: context.getScreenWidth(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      StatusBadge(
                        label: badgeLabel ?? statusInfo.label,
                        color: statusInfo.color,
                        bgColor: statusInfo.bgColor,
                      ),
                    ],
                  ),
                ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
