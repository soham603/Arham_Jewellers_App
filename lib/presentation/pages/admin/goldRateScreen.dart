import 'package:ratnesh_gold_app/utils/ToastUtil.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/GoldRateController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class GoldRateScreen extends StatefulWidget {
  const GoldRateScreen({super.key});

  @override
  State<GoldRateScreen> createState() => _GoldRateScreenState();
}

class _GoldRateScreenState extends State<GoldRateScreen> {
  final GoldRateController controller = Get.find<GoldRateController>();
  final TextEditingController _rateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Gold Rate',
          style: TextStyle(
            fontSize: context.getResponsiveSize(5.5),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh_,
        color: context.colorPalette.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            context.getResponsiveSize(4),
            context.heightPercent(1.5),
            context.getResponsiveSize(4),
            context.heightPercent(3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _currentRateCard(context),
              SizedBox(height: context.heightPercent(2.5)),
              _setRateButton(context),
              SizedBox(height: context.heightPercent(3)),
              Text(
                'Rate History',
                style: TextStyle(
                  fontSize: context.getResponsiveSize(5),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: context.heightPercent(1.5)),
              _fallbackBanner(context),
              _historyList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _currentRateCard(BuildContext context) {
    return Obx(() {
      final rate = controller.currentRate;
      final rateState = controller.currentRateState;

      if (rateState == CurrentAppState.LOADING && rate == null) {
        return _shimmerCard(context);
      }

      if (rateState == CurrentAppState.ERROR && rate == null) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.getResponsiveSize(5)),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: context.getResponsiveSize(10),
                color: Colors.red.shade300,
              ),
              SizedBox(height: context.heightPercent(1)),
              Text(
                controller.error.isNotEmpty ? controller.error : 'Failed to load rate',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.getResponsiveSize(3.5),
                  color: Colors.red.shade400,
                ),
              ),
              SizedBox(height: context.heightPercent(1.5)),
              ElevatedButton(
                onPressed: controller.fetchCurrentRate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: context.getResponsiveSize(4),
          vertical: context.heightPercent(2),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1E1E), Color(0xFF2E2E2E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: context.getResponsiveSize(11),
              height: context.getResponsiveSize(11),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGold,
              ),
              child: Icon(
                Icons.monetization_on_rounded,
                color: Colors.white,
                size: context.getResponsiveSize(5.5),
              ),
            ),
            SizedBox(width: context.getResponsiveSize(3)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Today\'s Gold Rate',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: context.getResponsiveSize(3.2),
                    ),
                  ),
                  SizedBox(height: context.heightPercent(0.3)),
                  Text.rich(
                    rate != null
                        ? TextSpan(children: [
                            TextSpan(
                              text: '₹${NumberFormat.decimalPattern('en_IN').format(rate.rate)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: context.getResponsiveSize(7),
                                height: 1.0,
                              ),
                            ),
                            TextSpan(
                              text: '/10g',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                                fontSize: context.getResponsiveSize(3),
                                height: 1.0,
                              ),
                            ),
                          ])
                        : const TextSpan(
                            text: '—',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 32,
                              height: 1.1,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            if (rate != null)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.getResponsiveSize(2.5),
                  vertical: context.heightPercent(0.6),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _timeAgo(rate.timestamp),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: context.getResponsiveSize(2.6),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.isNegative) return 'just now';
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  Widget _setRateButton(BuildContext context) {
    return Obx(() {
      final isLoading = controller.actionState == CurrentAppState.LOADING;

      return GestureDetector(
        onTap: isLoading ? null : () => _showSetRateSheet(context),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: context.heightPercent(1.8)),
          decoration: BoxDecoration(
            color: AppColors.primaryGold,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGold.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isLoading
              ? Center(
                  child: SizedBox(
                    width: context.getResponsiveSize(5),
                    height: context.getResponsiveSize(5),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                    SizedBox(width: context.getResponsiveSize(2)),
                    Text(
                      'Set New Rate',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: context.getResponsiveSize(4),
                      ),
                    ),
                  ],
                ),
        ),
      );
    });
  }

  void _showSetRateSheet(BuildContext context) {
    _rateController.clear();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    final currentRate = controller.currentRate?.rate;
    if (currentRate != null) {
      _rateController.text = currentRate.toStringAsFixed(0);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              context.getResponsiveSize(5),
              context.heightPercent(2),
              context.getResponsiveSize(5),
              context.heightPercent(3),
            ),
            decoration: BoxDecoration(
              color: context.colorPalette.backgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: context.getResponsiveSize(10),
                    height: context.heightPercent(0.5),
                    decoration: BoxDecoration(
                      color: context.colorPalette.subTitleColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                SizedBox(height: context.heightPercent(2)),
                Text(
                  'Set Gold Rate',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(5),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: context.heightPercent(0.5)),
                Text(
                  'Enter the new gold rate per 10 g',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3.5),
                    color: context.colorPalette.subTitleColor,
                  ),
                ),
                SizedBox(height: context.heightPercent(2.5)),
                TextField(
                  controller: _rateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(5),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: TextStyle(
                      fontSize: context.getResponsiveSize(5),
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGold,
                    ),
                    hintText: 'e.g. 7200',
                    hintStyle: TextStyle(
                      color: context.colorPalette.subTitleColor.withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: context.colorPalette.boxColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppColors.primaryGold,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: context.heightPercent(2)),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                      helpText: 'SELECT RATE DATE',
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
                    if (picked != null) {
                      setSheetState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.getResponsiveSize(4),
                      vertical: context.heightPercent(1.5),
                    ),
                    decoration: BoxDecoration(
                      color: context.colorPalette.boxColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: context.colorPalette.subTitleColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: context.getResponsiveSize(8),
                          height: context.getResponsiveSize(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: context.getResponsiveSize(4),
                            color: AppColors.primaryGold,
                          ),
                        ),
                        SizedBox(width: context.getResponsiveSize(3)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rate Date',
                                style: TextStyle(
                                  fontSize: context.getResponsiveSize(2.8),
                                  color: context.colorPalette.subTitleColor,
                                ),
                              ),
                              SizedBox(height: context.heightPercent(0.3)),
                              Text(
                                DateFormat('dd MMM yyyy').format(_selectedDate),
                                style: TextStyle(
                                  fontSize: context.getResponsiveSize(3.8),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: context.getResponsiveSize(5),
                          color: context.colorPalette.subTitleColor,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: context.heightPercent(1.5)),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: AppColors.primaryGold,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: AppColors.textDark,
                          ),
                          timePickerTheme: TimePickerThemeData(
                            hourMinuteTextStyle: TextStyle(
                              fontSize: ctx.responsiveFont(40),
                              fontWeight: FontWeight.w600,
                            ),
                            dayPeriodTextStyle: TextStyle(
                              fontSize: ctx.responsiveFont(14),
                              fontWeight: FontWeight.w600,
                            ),
                            dialTextStyle: TextStyle(
                              fontSize: ctx.responsiveFont(12),
                            ),
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setSheetState(() {
                        _selectedTime = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.getResponsiveSize(4),
                      vertical: context.heightPercent(1.5),
                    ),
                    decoration: BoxDecoration(
                      color: context.colorPalette.boxColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: context.colorPalette.subTitleColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: context.getResponsiveSize(8),
                          height: context.getResponsiveSize(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.access_time_rounded,
                            size: context.getResponsiveSize(4),
                            color: AppColors.primaryGold,
                          ),
                        ),
                        SizedBox(width: context.getResponsiveSize(3)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rate Time',
                                style: TextStyle(
                                  fontSize: context.getResponsiveSize(2.8),
                                  color: context.colorPalette.subTitleColor,
                                ),
                              ),
                              SizedBox(height: context.heightPercent(0.3)),
                              Text(
                                _selectedTime.format(context),
                                style: TextStyle(
                                  fontSize: context.getResponsiveSize(3.8),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: context.getResponsiveSize(5),
                          color: context.colorPalette.subTitleColor,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: context.heightPercent(2.5)),
                Obx(() {
                  final isLoading = controller.actionState == CurrentAppState.LOADING;

                  return GestureDetector(
                    onTap: isLoading
                        ? null
                        : () async {
                            final text = _rateController.text.trim().replaceAll(',', '');
                            final rate = double.tryParse(text);
                            if (rate == null || rate < 0.1 || rate > 1000000) {
                              ToastUtils.showWarning('Enter a rate between ₹0.10 and ₹10,00,000');
                              return;
                            }
                            Get.back();
                            final combinedDateTime = DateTime(
                              _selectedDate.year,
                              _selectedDate.month,
                              _selectedDate.day,
                              _selectedTime.hour,
                              _selectedTime.minute,
                            );
                            controller.setRate(rate: rate, date: combinedDateTime);
                          },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: context.heightPercent(1.5)),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: isLoading
                          ? Center(
                              child: SizedBox(
                                width: context.getResponsiveSize(5),
                                height: context.getResponsiveSize(5),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Update Rate',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: context.getResponsiveSize(4.2),
                              ),
                            ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallbackBanner(BuildContext context) {
    return Obx(() {
      final msg = controller.fallbackMessage;
      if (msg.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: EdgeInsets.only(bottom: context.heightPercent(1.5)),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: context.getResponsiveSize(3.5),
            vertical: context.heightPercent(1),
          ),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: context.getResponsiveSize(3.5),
                color: Colors.orange.shade700,
              ),
              SizedBox(width: context.getResponsiveSize(2)),
              Expanded(
                child: Text(
                  msg,
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3),
                    fontWeight: FontWeight.w500,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _historyList(BuildContext context) {
    return Obx(() {
      final histState = controller.historyState;
      final history = controller.history;

      if (histState == CurrentAppState.LOADING && history.isEmpty) {
        return Column(
          children: List.generate(
            5,
            (_) => Padding(
              padding: EdgeInsets.only(bottom: context.heightPercent(1)),
              child: _shimmerHistoryTile(context),
            ),
          ),
        );
      }

      if (histState == CurrentAppState.ERROR && history.isEmpty) {
        return Center(
          child: Text(
            controller.error.isNotEmpty ? controller.error : 'No history available',
            style: TextStyle(
              fontSize: context.getResponsiveSize(3.5),
              color: context.colorPalette.subTitleColor,
            ),
          ),
        );
      }

      if (history.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: context.heightPercent(3)),
            child: Column(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: context.getResponsiveSize(12),
                  color: context.colorPalette.subTitleColor.withValues(alpha: 0.4),
                ),
                SizedBox(height: context.heightPercent(1)),
                Text(
                  'No rate history yet',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3.8),
                    color: context.colorPalette.subTitleColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        children: [
          ...List.generate(history.length, (index) {
            final rate = history[index];
            final isFirst = index == 0;
            final prevRate = index < history.length - 1 ? history[index + 1].rate : null;

            return Padding(
              padding: EdgeInsets.only(bottom: context.heightPercent(1)),
              child: _historyTile(context, rate, isFirst, prevRate),
            );
          }),
        ],
      );
    });
  }

  Widget _historyTile(
    BuildContext context,
    dynamic rate,
    bool isFirst,
    double? prevRate,
  ) {
    final diff = prevRate != null ? rate.rate - prevRate : 0.0;
    final isUp = diff > 0;

    return Container(
      padding: EdgeInsets.all(context.getResponsiveSize(4)),
      decoration: BoxDecoration(
        color: context.colorPalette.boxColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.colorPalette.subTitleColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: context.getResponsiveSize(10),
            height: context.getResponsiveSize(10),
            decoration: BoxDecoration(
              color: isFirst
                  ? AppColors.primaryGold.withValues(alpha: 0.12)
                  : context.colorPalette.subTitleColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
              child: Center(
                child: Text(
                  DateFormat('dd').format(rate.timestamp.toLocal()),
                style: TextStyle(
                  fontSize: context.getResponsiveSize(3.2),
                  fontWeight: FontWeight.w700,
                  color: isFirst ? AppColors.primaryGold : context.colorPalette.subTitleColor,
                ),
              ),
            ),
          ),
          SizedBox(width: context.getResponsiveSize(3)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd MMMM yyyy').format(rate.timestamp.toLocal()),
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3.5),
                    fontWeight: FontWeight.w600,
                    color: context.colorPalette.textColor,
                  ),
                ),
                if (rate.source != null)
                  Text(
                    'Set by ${rate.source}',
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(2.8),
                      color: context.colorPalette.subTitleColor,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${rate.rate.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: context.getResponsiveSize(4.2),
                  fontWeight: FontWeight.w700,
                  color: context.colorPalette.textColor,
                ),
              ),
              if (!isFirst && diff != 0)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.getResponsiveSize(1.5),
                    vertical: context.heightPercent(0.2),
                  ),
                  decoration: BoxDecoration(
                    color: isUp
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        size: context.getResponsiveSize(2.5),
                        color: isUp ? Colors.green : Colors.red,
                      ),
                      SizedBox(width: 2),
                      Text(
                        '₹${diff.abs().toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: context.getResponsiveSize(2.5),
                          fontWeight: FontWeight.w600,
                          color: isUp ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shimmerCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: context.heightPercent(22),
      decoration: BoxDecoration(
        color: context.colorPalette.shimmerBaseColor,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  Widget _shimmerHistoryTile(BuildContext context) {
    return Container(
      height: context.heightPercent(8),
      decoration: BoxDecoration(
        color: context.colorPalette.shimmerBaseColor,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
