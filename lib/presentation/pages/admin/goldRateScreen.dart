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
            fontSize: context.getFontSize(5.5),
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
            context.getScreenWidth(4),
            context.getScreenHeight(1.5),
            context.getScreenWidth(4),
            context.getScreenHeight(3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _currentRateCard(context),
              SizedBox(height: context.getScreenHeight(2.5)),
              _setRateButton(context),
              SizedBox(height: context.getScreenHeight(3)),
              Text(
                'Rate History',
                style: TextStyle(
                  fontSize: context.getFontSize(5),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: context.getScreenHeight(1.5)),
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
          padding: EdgeInsets.all(context.getScreenWidth(5)),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: context.getScreenWidth(10),
                color: Colors.red.shade300,
              ),
              SizedBox(height: context.getScreenHeight(1)),
              Text(
                controller.error.isNotEmpty ? controller.error : 'Failed to load rate',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.getFontSize(3.5),
                  color: Colors.red.shade400,
                ),
              ),
              SizedBox(height: context.getScreenHeight(1.5)),
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
          horizontal: context.getScreenWidth(4),
          vertical: context.getScreenHeight(1.5),
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
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: context.getScreenWidth(10),
              height: context.getScreenWidth(10),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGold,
              ),
              child: Icon(
                Icons.monetization_on_rounded,
                color: Colors.white,
                size: context.getScreenWidth(5),
              ),
            ),
            SizedBox(width: context.getScreenWidth(3)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Current Rate',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: context.getFontSize(3.2),
                    ),
                  ),
                  SizedBox(height: context.getScreenHeight(0.3)),
                  Text.rich(
                    rate != null
                        ? TextSpan(children: [
                            TextSpan(
                              text: '₹${NumberFormat.decimalPattern('en_IN').format(rate.rate)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: context.getFontSize(7),
                                height: 1.1,
                              ),
                            ),
                            TextSpan(
                              text: '/10g',
                              style: TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.w400,
                                fontSize: context.getFontSize(3),
                                height: 1.1,
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
            if (rate?.source != null)
              Expanded(
                flex: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      rate!.source!,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: context.getFontSize(2.2),
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM, hh:mm a').format(rate.timestamp.toLocal()),
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: context.getFontSize(2),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _setRateButton(BuildContext context) {
    return Obx(() {
      final isLoading = controller.actionState == CurrentAppState.LOADING;

      return GestureDetector(
        onTap: isLoading ? null : () => _showSetRateSheet(context),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(1.8)),
          decoration: BoxDecoration(
            color: AppColors.primaryGold,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGold.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isLoading
              ? Center(
                  child: SizedBox(
                    width: context.getScreenWidth(5),
                    height: context.getScreenWidth(5),
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
                    SizedBox(width: context.getScreenWidth(2)),
                    Text(
                      'Set New Rate',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: context.getFontSize(4),
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
    final currentRate = controller.currentRate?.rate;
    if (currentRate != null) {
      _rateController.text = currentRate.toStringAsFixed(0);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            context.getScreenWidth(5),
            context.getScreenHeight(2),
            context.getScreenWidth(5),
            context.getScreenHeight(3),
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
                  width: context.getScreenWidth(10),
                  height: context.getScreenHeight(0.5),
                  decoration: BoxDecoration(
                    color: context.colorPalette.subTitleColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              SizedBox(height: context.getScreenHeight(2)),
              Text(
                'Set Gold Rate',
                style: TextStyle(
                  fontSize: context.getFontSize(5),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: context.getScreenHeight(0.5)),
              Text(
                'Enter the new gold rate per 10 g',
                style: TextStyle(
                  fontSize: context.getFontSize(3.5),
                  color: context.colorPalette.subTitleColor,
                ),
              ),
              SizedBox(height: context.getScreenHeight(2.5)),
              TextField(
                controller: _rateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: TextStyle(
                  fontSize: context.getFontSize(5),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(
                    fontSize: context.getFontSize(5),
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGold,
                  ),
                  hintText: 'e.g. 7200',
                  hintStyle: TextStyle(
                    color: context.colorPalette.subTitleColor.withOpacity(0.4),
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
              SizedBox(height: context.getScreenHeight(2.5)),
              Obx(() {
                final isLoading = controller.actionState == CurrentAppState.LOADING;

                return GestureDetector(
                  onTap: isLoading
                      ? null
                      : () async {
                          final text = _rateController.text.trim().replaceAll(',', '');
                          final rate = double.tryParse(text);
if (rate == null || rate < 0.1 || rate > 1000000) {
  Get.snackbar('Invalid', 'Enter a rate between ₹0.10 and ₹10,00,000');
                            return;
                          }
                          Get.back();
                          controller.setRate(rate: rate);
                        },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(1.5)),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: isLoading
                        ? Center(
                            child: SizedBox(
                              width: context.getScreenWidth(5),
                              height: context.getScreenWidth(5),
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
                              fontSize: context.getFontSize(4.2),
                            ),
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
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
              padding: EdgeInsets.only(bottom: context.getScreenHeight(1)),
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
              fontSize: context.getFontSize(3.5),
              color: context.colorPalette.subTitleColor,
            ),
          ),
        );
      }

      if (history.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(3)),
            child: Column(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: context.getScreenWidth(12),
                  color: context.colorPalette.subTitleColor.withOpacity(0.4),
                ),
                SizedBox(height: context.getScreenHeight(1)),
                Text(
                  'No rate history yet',
                  style: TextStyle(
                    fontSize: context.getFontSize(3.8),
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
              padding: EdgeInsets.only(bottom: context.getScreenHeight(1)),
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
      padding: EdgeInsets.all(context.getScreenWidth(4)),
      decoration: BoxDecoration(
        color: context.colorPalette.boxColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.colorPalette.subTitleColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: context.getScreenWidth(10),
            height: context.getScreenWidth(10),
            decoration: BoxDecoration(
              color: isFirst
                  ? AppColors.primaryGold.withOpacity(0.12)
                  : context.colorPalette.subTitleColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
              child: Center(
                child: Text(
                  DateFormat('dd').format(rate.timestamp.toLocal()),
                style: TextStyle(
                  fontSize: context.getFontSize(3.2),
                  fontWeight: FontWeight.w700,
                  color: isFirst ? AppColors.primaryGold : context.colorPalette.subTitleColor,
                ),
              ),
            ),
          ),
          SizedBox(width: context.getScreenWidth(3)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd MMMM yyyy').format(rate.timestamp.toLocal()),
                  style: TextStyle(
                    fontSize: context.getFontSize(3.5),
                    fontWeight: FontWeight.w600,
                    color: context.colorPalette.textColor,
                  ),
                ),
                if (rate.source != null)
                  Text(
                    'Set by ${rate.source}',
                    style: TextStyle(
                      fontSize: context.getFontSize(2.8),
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
                  fontSize: context.getFontSize(4.2),
                  fontWeight: FontWeight.w700,
                  color: context.colorPalette.textColor,
                ),
              ),
              if (!isFirst && diff != 0)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.getScreenWidth(1.5),
                    vertical: context.getScreenHeight(0.2),
                  ),
                  decoration: BoxDecoration(
                    color: isUp
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        size: context.getScreenWidth(2.5),
                        color: isUp ? Colors.green : Colors.red,
                      ),
                      SizedBox(width: 2),
                      Text(
                        '₹${diff.abs().toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: context.getFontSize(2.5),
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
      height: context.getScreenHeight(22),
      decoration: BoxDecoration(
        color: context.colorPalette.shimmerBaseColor,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  Widget _shimmerHistoryTile(BuildContext context) {
    return Container(
      height: context.getScreenHeight(8),
      decoration: BoxDecoration(
        color: context.colorPalette.shimmerBaseColor,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
