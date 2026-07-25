import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class CompleteOrderDialog extends StatefulWidget {
  final String? subtitle;
  final Future<bool> Function(String? deliveryDate, String? completeAdminNotes) onConfirm;
  final bool showCancel;

  const CompleteOrderDialog({
    super.key,
    this.subtitle,
    required this.onConfirm,
    this.showCancel = true,
  });

  static void show({
    String? subtitle,
    required Future<bool> Function(String? deliveryDate, String? completeAdminNotes) onConfirm,
    bool showCancel = true,
  }) {
    Get.dialog(
      CompleteOrderDialog(
        subtitle: subtitle,
        onConfirm: onConfirm,
        showCancel: showCancel,
      ),
      barrierDismissible: false,
    );
  }

  @override
  State<CompleteOrderDialog> createState() => _CompleteOrderDialogState();
}

class _CompleteOrderDialogState extends State<CompleteOrderDialog> {
  final dateController = TextEditingController();
  final notesController = TextEditingController();
  DateTime? selectedDate;
  bool _submitting = false;

  @override
  void dispose() {
    dateController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(6)),
        child: Padding(
          padding: EdgeInsets.all(context.getResponsiveSize(6)),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mark as Completed",
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: context.getResponsiveSize(5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                  SizedBox(height: context.heightPercent(0.8)),
                  Text(
                    widget.subtitle!,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: context.getResponsiveSize(3.4),
                    ),
                  ),
                ],
                SizedBox(height: context.heightPercent(2)),
                Text(
                  "Delivery Date",
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3.3),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: context.heightPercent(0.8)),
                GestureDetector(
                  onTap: _submitting
                      ? null
                      : () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            helpText: 'SELECT DELIVERY DATE',
                            builder: (ctx, child) => Theme(
                              data: Theme.of(ctx).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: AppColors.primaryGold,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: AppColors.textDark,
                                ),
                                datePickerTheme: DatePickerThemeData(
                                  headerHeadlineStyle: TextStyle(
                                    fontSize: ctx.responsiveFont(22),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  headerHelpStyle: TextStyle(
                                    fontSize: ctx.responsiveFont(13),
                                  ),
                                  dayStyle: TextStyle(
                                    fontSize: ctx.responsiveFont(14),
                                  ),
                                  weekdayStyle: TextStyle(
                                    fontSize: ctx.responsiveFont(12),
                                  ),
                                  dayShape: WidgetStateProperty.all(
                                    const CircleBorder(),
                                  ),
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (date != null) {
                            setState(() {
                              selectedDate = date;
                              dateController.text = '${date.day}/${date.month}/${date.year}';
                            });
                          }
                        },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: dateController,
                      style: TextStyle(
                        fontSize: context.getResponsiveSize(3.6),
                      ),
                      decoration: InputDecoration(
                        hintText: "Select delivery date (optional)",
                        hintStyle: TextStyle(
                          fontSize: context.getResponsiveSize(3.4),
                          color: Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: AppColors.pageBg,
                        suffixIcon: Icon(
                          Icons.calendar_today_rounded,
                          color: AppColors.primaryGold,
                          size: 20,
                        ),
                        contentPadding: EdgeInsets.all(context.getResponsiveSize(3)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF2563EB),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: context.heightPercent(2)),
                Text(
                  "Completion Notes",
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3.3),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: context.heightPercent(0.8)),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  enabled: !_submitting,
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3.6),
                  ),
                  decoration: InputDecoration(
                    hintText: "Optional notes",
                    hintStyle: TextStyle(
                      fontSize: context.getResponsiveSize(3.4),
                      color: Colors.grey.shade400,
                    ),
                    filled: true,
                    fillColor: AppColors.pageBg,
                    contentPadding: EdgeInsets.all(context.getResponsiveSize(3)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: context.heightPercent(2.5)),
                if (widget.showCancel)
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _submitting ? null : () => Get.back(),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: context.getResponsiveSize(3.6),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: context.getResponsiveSize(3)),
                      Expanded(
                        child: _buildConfirmButton(),
                      ),
                    ],
                  )
                else
                  _buildConfirmButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: context.heightPercent(5.5),
      child: ElevatedButton(
        onPressed: _submitting
            ? null
            : () async {
                setState(() => _submitting = true);
                Get.back();
                final success = await widget.onConfirm(
                  selectedDate?.toIso8601String().split('T').first,
                  notesController.text.trim(),
                );
                if (!success && mounted) {
                  setState(() => _submitting = false);
                }
              },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryGoldDark,
          padding: EdgeInsets.symmetric(
            vertical: context.heightPercent(1.2),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                "Confirm",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: context.getResponsiveSize(3.6),
                ),
              ),
      ),
    );
  }
}
