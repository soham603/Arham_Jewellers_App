import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class PdfLoadingDialog extends StatelessWidget {
  final String message;
  final ValueNotifier<double>? progress;
  final VoidCallback? onCancel;
  final bool? showProgress;

  const PdfLoadingDialog({
    super.key,
    required this.message,
    this.progress,
    this.onCancel,
    this.showProgress,
  });

  bool get _showProgress => showProgress ?? progress != null;

  static Future<void> show(
    BuildContext context, {
    required String message,
    ValueNotifier<double>? progress,
    VoidCallback? onCancel,
    bool? showProgress,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: PdfLoadingDialog(
          message: message,
          progress: progress,
          onCancel: onCancel,
          showProgress: showProgress,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final useProgress = _showProgress && progress != null;
    return Center(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(context.getResponsiveSize(8)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (useProgress)
                _buildPercentageRow(context)
              else
                _buildSpinner(context),
              if (!useProgress) ...[
                SizedBox(height: context.heightPercent(1.5)),
                _buildMessage(context),
              ],
              if (onCancel != null) ...[
                SizedBox(height: context.heightPercent(2.5)),
                _buildCancelButton(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpinner(BuildContext context) {
    return SizedBox(
      width: context.getResponsiveSize(5),
      height: context.getResponsiveSize(5),
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: context.colorPalette.gold,
      ),
    );
  }

  Widget _buildPercentageRow(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: context.getResponsiveSize(5),
          height: context.getResponsiveSize(5),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.colorPalette.gold,
          ),
        ),
        SizedBox(width: context.getResponsiveSize(2)),
        ValueListenableBuilder<double>(
          valueListenable: progress!,
          builder: (context, value, _) => Text(
            '${(value * 100).toInt()}%',
            style: TextStyle(
              fontSize: context.getResponsiveSize(5),
              fontWeight: FontWeight.w700,
              color: context.colorPalette.gold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(BuildContext context) {
    return Text(
      message,
      style: TextStyle(
        fontSize: context.getResponsiveSize(3.5),
        fontWeight: FontWeight.w500,
        color: context.colorPalette.textColor,
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        onCancel!();
      },
      child: Text(
        'Cancel',
        style: TextStyle(
          fontSize: context.getResponsiveSize(3.5),
          fontWeight: FontWeight.w600,
          color: context.colorPalette.subTitleColor,
        ),
      ),
    );
  }
}
