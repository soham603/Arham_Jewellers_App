import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/utils/formatters.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/StockSyncController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class StockSyncPage extends StatelessWidget {
  const StockSyncPage({super.key});

  static const _sentinel = '2000-01-01 00:00:00';

  @override
  Widget build(BuildContext context) {
    final ctrl = StockSyncController.instance;

    return Scaffold(
      backgroundColor: context.colorPalette.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.colorPalette.backgroundColor,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: context.colorPalette.textColor,
          ),
        ),
        title: Text(
          'Stock Sync',
          style: TextStyle(
            color: context.colorPalette.textColor,
            fontSize: context.getResponsiveSize(5),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: context.getResponsiveSize(4),
          vertical: context.heightPercent(1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pull the latest stock and product data from the Alpha ERP and queue image updates.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: context.getResponsiveSize(3.4),
              ),
            ),
            SizedBox(height: context.heightPercent(2)),
            Obx(() => _runningCard(context, ctrl)),
            _fullSyncCard(context, ctrl),
            SizedBox(height: context.heightPercent(2)),
            _backfillCard(context, ctrl),
            Obx(() => _resultCard(context, ctrl)),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.getResponsiveSize(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7DED2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _runningCard(BuildContext context, StockSyncController ctrl) {
    if (!ctrl.isRunning) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: context.heightPercent(2)),
      child: _card(
        context,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryGold,
                ),
              ),
              SizedBox(width: context.getResponsiveSize(2)),
              Text(
                'Syncing… ${_formatElapsed(ctrl.elapsed)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  fontSize: context.getResponsiveSize(4),
                ),
              ),
            ],
          ),
          SizedBox(height: context.heightPercent(1.5)),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              backgroundColor: Color(0xFFF5EFE7),
              color: AppColors.primaryGold,
              minHeight: 8,
            ),
          ),
          SizedBox(height: context.heightPercent(1)),
          Text(
            'This keeps running on the server even if you leave this screen.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: context.getResponsiveSize(3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fullSyncCard(BuildContext context, StockSyncController ctrl) {
    return _card(
      context,
      children: [
        Row(
          children: [
            const Icon(Icons.shield_moon_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: context.getResponsiveSize(2)),
            Expanded(
              child: Text(
                'Full catalog sync',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  fontSize: context.getResponsiveSize(4.2),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: context.heightPercent(1)),
        Text(
          'Re-pulls the entire Alpha catalog to reconcile anything the incremental sync missed (e.g. backdated changes). Runs immediately and is best run off-peak — a scheduled sync that overlaps is skipped.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: context.getResponsiveSize(3.2),
          ),
        ),
        SizedBox(height: context.heightPercent(2)),
        Container(
          padding: EdgeInsets.all(context.getResponsiveSize(3)),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE3A7)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFB45309),
                size: 18,
              ),
              SizedBox(width: context.getResponsiveSize(2)),
              Expanded(
                child: Text(
                  'This pulls the entire Alpha catalog and may take several minutes.',
                  style: TextStyle(
                    color: const Color(0xFF92400E),
                    fontSize: context.getResponsiveSize(3.2),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.heightPercent(2)),
        SizedBox(
          width: double.infinity,
          child: Obx(
            () => ElevatedButton.icon(
              onPressed: ctrl.isRunning
                  ? null
                  : () => _confirmFullSync(context, ctrl),
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Run full sync'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primaryGold.withValues(
                  alpha: 0.5,
                ),
                padding: EdgeInsets.symmetric(
                  vertical: context.heightPercent(1.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _backfillCard(BuildContext context, StockSyncController ctrl) {
    return _card(
      context,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, color: AppColors.primaryGold),
            SizedBox(width: context.getResponsiveSize(2)),
            Expanded(
              child: Text(
                'Advanced: backfill from a date',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  fontSize: context.getResponsiveSize(4.2),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: context.heightPercent(1)),
        Text(
          'Pulls every product changed since the selected date. Useful to recover backdated changes the incremental sync missed.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: context.getResponsiveSize(3.2),
          ),
        ),
        SizedBox(height: context.heightPercent(2)),
        Obx(
          () => GestureDetector(
            onTap: ctrl.isRunning ? null : () => _pickOverride(context, ctrl),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: context.getResponsiveSize(3),
                vertical: context.heightPercent(1.5),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF5EFE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                  SizedBox(width: context.getResponsiveSize(2)),
                  Expanded(
                    child: Text(
                      ctrl.overrideDate.value == null
                          ? 'Select date & time'
                          : formatDate(
                              ctrl.overrideDate.value!,
                              pattern: 'dd MMM yyyy • hh:mm a',
                            ),
                      style: TextStyle(
                        color: ctrl.overrideDate.value == null
                            ? AppColors.textMuted
                            : AppColors.textDark,
                        fontWeight: ctrl.overrideDate.value == null
                            ? FontWeight.w400
                            : FontWeight.w600,
                        fontSize: context.getResponsiveSize(3.6),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: context.heightPercent(1.5)),
        Obx(
          () => Wrap(
            spacing: context.getResponsiveSize(2),
            runSpacing: context.heightPercent(0.8),
            children: [
              _presetButton(
                context,
                ctrl,
                'Last 7 days',
                DateTime.now().subtract(const Duration(days: 7)),
              ),
              _presetButton(
                context,
                ctrl,
                'Last 30 days',
                DateTime.now().subtract(const Duration(days: 30)),
              ),
              _presetButton(
                context,
                ctrl,
                'Start of year',
                DateTime(DateTime.now().year, 1, 1, 0, 0),
              ),
              _presetButton(
                context,
                ctrl,
                'Beginning of time',
                DateTime(2000, 1, 1, 0, 0),
              ),
            ],
          ),
        ),
        SizedBox(height: context.heightPercent(2)),
        SizedBox(
          width: double.infinity,
          child: Obx(
            () => ElevatedButton.icon(
              onPressed: (ctrl.isRunning || ctrl.overrideDate.value == null)
                  ? null
                  : () => _confirmBackfill(context, ctrl),
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Run backfill'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primaryGold.withValues(
                  alpha: 0.5,
                ),
                padding: EdgeInsets.symmetric(
                  vertical: context.heightPercent(1.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _presetButton(
    BuildContext context,
    StockSyncController ctrl,
    String label,
    DateTime value,
  ) {
    return OutlinedButton(
      onPressed: ctrl.isRunning ? null : () => ctrl.overrideDate.value = value,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textDark,
        padding: EdgeInsets.symmetric(
          horizontal: context.getResponsiveSize(3),
          vertical: context.heightPercent(0.6),
        ),
        side: const BorderSide(color: Color(0xFFE7DED2)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: context.getResponsiveSize(3)),
      ),
    );
  }

  Widget _resultCard(BuildContext context, StockSyncController ctrl) {
    final result = ctrl.result;
    if (result == null) return const SizedBox.shrink();

    final summary = result.summary;
    final failed = (summary.imagesFailed ?? 0) + (summary.dbFailed ?? 0);
    final ranAt =
        summary.syncRunAt ??
        formatDate(result.ranAt, pattern: 'dd MMM yyyy • hh:mm a');
    final title = result.kind == StockSyncKind.full
        ? 'Full catalog sync result'
        : 'Backfill result';

    return Padding(
      padding: EdgeInsets.only(top: context.heightPercent(2)),
      child: _card(
        context,
        children: [
          Row(
            children: [
              Icon(
                failed > 0
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_rounded,
                color: failed > 0 ? const Color(0xFFF59E0B) : Colors.green,
              ),
              SizedBox(width: context.getResponsiveSize(2)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    fontSize: context.getResponsiveSize(4.2),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.heightPercent(1)),
          Text(
            result.message,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: context.getResponsiveSize(3.2),
            ),
          ),
          SizedBox(height: context.heightPercent(1.5)),
          Text(
            'Ran at ${ranAt.isEmpty ? '—' : ranAt}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
              fontSize: context.getResponsiveSize(3.4),
            ),
          ),
          SizedBox(height: context.heightPercent(1.5)),
          LayoutBuilder(
            builder: (context, constraints) {
              final spacing = context.getResponsiveSize(2.5);
              final columns = constraints.maxWidth >= 600 ? 4 : 2;
              final width =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              final stats = <MapEntry<String, String>>[
                MapEntry('From API', '${summary.totalFromApi ?? '—'}'),
                MapEntry('Created', '${summary.created ?? '—'}'),
                MapEntry('Updated', '${summary.updated ?? '—'}'),
                MapEntry('Images queued', '${summary.imagesQueued ?? '—'}'),
                MapEntry('Images synced', '${summary.imagesSuccess ?? '—'}'),
                MapEntry('Image failures', '${summary.imagesFailed ?? '—'}'),
                MapEntry('DB failures', '${summary.dbFailed ?? '—'}'),
                MapEntry('Duration', summary.duration ?? '—'),
              ];
              return Wrap(
                spacing: spacing,
                runSpacing: context.heightPercent(1),
                children: stats
                    .map(
                      (s) => SizedBox(
                        width: width,
                        child: _statCell(context, s.key, s.value),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          if (summary.lastSyncDate != null) ...[
            SizedBox(height: context.heightPercent(1.5)),
            _badge(
              context,
              summary.lastSyncDate == _sentinel
                  ? 'Last sync: backfilled from the beginning'
                  : 'Last sync: ${summary.lastSyncDate}',
              const Color(0xFFF5EFE7),
              AppColors.textDark,
            ),
          ],
          if (failed > 0) ...[
            SizedBox(height: context.heightPercent(1)),
            _badge(
              context,
              '${summary.imagesFailed ?? 0} image / ${summary.dbFailed ?? 0} DB failures',
              const Color(0xFFFFF7E6),
              const Color(0xFFB45309),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statCell(BuildContext context, String label, String value) {
    return Container(
      padding: EdgeInsets.all(context.getResponsiveSize(3)),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE7DED2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: context.getResponsiveSize(2.7),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: context.heightPercent(0.4)),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              fontSize: context.getResponsiveSize(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(BuildContext context, String text, Color bg, Color fg) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.getResponsiveSize(3),
        vertical: context.heightPercent(0.4),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: context.getResponsiveSize(3),
        ),
      ),
    );
  }

  Future<void> _pickOverride(
    BuildContext context,
    StockSyncController ctrl,
  ) async {
    final now = DateTime.now();
    final initial = ctrl.overrideDate.value ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'SELECT BACKFILL DATE',
      builder: _pickerTheme,
    );
    if (date == null) return;
    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'SELECT TIME',
      builder: _pickerTheme,
    );
    if (time == null) return;
    ctrl.overrideDate.value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Widget _pickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaryGold,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: AppColors.textDark,
        ),
      ),
      child: child!,
    );
  }

  Future<void> _confirmFullSync(
    BuildContext context,
    StockSyncController ctrl,
  ) async {
    final acked = await _showConfirm(
      context,
      title: 'Run a full catalog sync?',
      description:
          'This pulls the entire Alpha catalog and can update many products and images. It may take several minutes.',
      requireAck: true,
      ackLabel:
          'I understand this pulls the entire Alpha catalog and may take several minutes',
      confirmLabel: 'Yes, continue',
    );
    if (acked == true) await ctrl.runFull();
  }

  Future<void> _confirmBackfill(
    BuildContext context,
    StockSyncController ctrl,
  ) async {
    final date = ctrl.overrideDate.value;
    final dateLabel = date == null
        ? 'the selected date'
        : formatDate(date, pattern: 'dd MMM yyyy • hh:mm a');
    final acked = await _showConfirm(
      context,
      title: 'Backfill from the override date?',
      description:
          'This pulls every product changed since $dateLabel and may take a few minutes.',
      requireAck: false,
      confirmLabel: 'Yes, continue',
    );
    if (acked == true) await ctrl.runBackfill();
  }

  Future<bool?> _showConfirm(
    BuildContext context, {
    required String title,
    required String description,
    required bool requireAck,
    required String confirmLabel,
    String? ackLabel,
  }) {
    var acked = !requireAck;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: context.colorPalette.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              fontSize: context.getResponsiveSize(4.5),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: TextStyle(
                  color: context.colorPalette.textColor,
                  fontSize: context.getResponsiveSize(3.5),
                ),
              ),
              if (requireAck && ackLabel != null) ...[
                SizedBox(height: context.heightPercent(1.5)),
                GestureDetector(
                  onTap: () => setDialogState(() => acked = !acked),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: acked,
                        onChanged: (value) =>
                            setDialogState(() => acked = value ?? false),
                        activeColor: AppColors.primaryGold,
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: context.heightPercent(1),
                          ),
                          child: Text(
                            ackLabel,
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: context.getResponsiveSize(3.3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: context.colorPalette.subTitleColor),
              ),
            ),
            ElevatedButton(
              onPressed: acked
                  ? () => Navigator.of(dialogContext).pop(true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                confirmLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatElapsed(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    String pad(int n) => n.toString().padLeft(2, '0');
    return hours > 0
        ? '${pad(hours)}:${pad(minutes)}:${pad(seconds)}'
        : '${pad(minutes)}:${pad(seconds)}';
  }
}
