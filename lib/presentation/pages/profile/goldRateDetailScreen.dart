import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/date_range_picker_sheet.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/goldRateModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/GoldRateController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class GoldRateDetailScreen extends StatefulWidget {
  const GoldRateDetailScreen({super.key});

  @override
  State<GoldRateDetailScreen> createState() => _GoldRateDetailScreenState();
}

class _GoldRateDetailScreenState extends State<GoldRateDetailScreen> {
  final GoldRateController controller = Get.find<GoldRateController>();

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
            fontSize: context.getScreenWidth(5.5),
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
              _statisticsSummary(context),
              SizedBox(height: context.getScreenHeight(2.5)),
              _graphPlaceholder(context),
              SizedBox(height: context.getScreenHeight(3)),
              _periodFilter(context),
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
                  fontSize: context.getScreenWidth(3.5),
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
                    'Today\'s Gold Rate',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: context.getScreenWidth(3.2),
                    ),
                  ),
                  SizedBox(height: context.getScreenHeight(0.3)),
                  Text(
                    rate != null ? '₹${rate.rate.toStringAsFixed(0)}/10g' : '—',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: context.getScreenWidth(7),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            if (rate != null)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.getScreenWidth(2),
                  vertical: context.getScreenHeight(0.3),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _timeAgo(rate.timestamp),
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: context.getScreenWidth(2.2),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _graphPlaceholder(BuildContext context) {
    return Obx(() {
      final history = controller.history;
      final histState = controller.historyState;

      if (histState == CurrentAppState.LOADING && history.isEmpty) {
        return Container(
          width: double.infinity,
          height: context.getScreenHeight(22),
          decoration: BoxDecoration(
            color: context.colorPalette.shimmerBaseColor,
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }

      if (history.length < 2) {
        return Container(
          width: double.infinity,
          height: context.getScreenHeight(20),
          decoration: BoxDecoration(
            color: context.colorPalette.boxColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: context.colorPalette.subTitleColor.withOpacity(0.15),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart_rounded,
                size: context.getScreenWidth(12),
                color: context.colorPalette.subTitleColor.withOpacity(0.4),
              ),
              SizedBox(height: context.getScreenHeight(1)),
              Text(
                'Need at least 2 data points for graph',
                style: TextStyle(
                  fontSize: context.getScreenWidth(3.5),
                  color: context.colorPalette.subTitleColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        );
      }

      final sorted = List<GoldRateModel>.from(history)..sort(
        (a, b) => a.timestamp.compareTo(b.timestamp),
      );

      final spots = <FlSpot>[];
      for (var i = 0; i < sorted.length; i++) {
        spots.add(FlSpot(i.toDouble(), sorted[i].rate));
      }

      final rates = spots.map((s) => s.y).toList();
      final minY = rates.reduce((a, b) => a < b ? a : b);
      final maxY = rates.reduce((a, b) => a > b ? a : b);
      final padding = (maxY - minY) * 0.15;

      final lineColor = AppColors.primaryGold;

      return Container(
        width: double.infinity,
        height: context.getScreenHeight(22),
        padding: EdgeInsets.fromLTRB(
          context.getScreenWidth(2),
          context.getScreenHeight(2),
          context.getScreenWidth(2),
          context.getScreenHeight(1),
        ),
        decoration: BoxDecoration(
          color: context.colorPalette.boxColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.colorPalette.subTitleColor.withOpacity(0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: context.getScreenWidth(1)),
              child: Text(
                'Gold Price Graph',
                style: TextStyle(
                  fontSize: context.getScreenWidth(3.8),
                  fontWeight: FontWeight.w600,
                  color: context.colorPalette.textColor,
                ),
              ),
            ),
            SizedBox(height: context.getScreenHeight(0.5)),
            Expanded(
              child: LineChart(
                LineChartData(
                  minY: minY - padding,
                  maxY: maxY + padding,
                  minX: 0,
                  maxX: (spots.length - 1).toDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval:
                        padding > 0 ? (padding * 2) / 3 : 100,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: context.colorPalette.subTitleColor.withOpacity(0.08),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: context.getScreenWidth(10),
                        interval: padding > 0 ? (padding * 2) / 3 : 100,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            '₹${(value / 1000).toStringAsFixed(1)}k',
                            style: TextStyle(
                              fontSize: context.getScreenWidth(2.2),
                              color: context.colorPalette.subTitleColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: context.getScreenHeight(3),
                        interval: spots.length > 7
                            ? (spots.length / 6).ceilToDouble()
                            : 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= sorted.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: EdgeInsets.only(
                              top: context.getScreenHeight(0.5),
                            ),
                            child: Text(
                              DateFormat('dd MMM').format(
                                sorted[idx].timestamp.toLocal(),
                              ),
                              style: TextStyle(
                                fontSize: context.getScreenWidth(2),
                                color: context.colorPalette.subTitleColor
                                    .withOpacity(0.5),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF1E1E1E),
                      tooltipRoundedRadius: 12,
                      tooltipPadding: EdgeInsets.symmetric(
                        horizontal: context.getScreenWidth(3),
                        vertical: context.getScreenHeight(0.8),
                      ),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final date = sorted[spot.x.toInt()].timestamp.toLocal();
                          return LineTooltipItem(
                            '₹${spot.y.toStringAsFixed(0)}\n',
                            TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: context.getScreenWidth(3),
                            ),
                            children: [
                              TextSpan(
                                text: DateFormat('dd MMM yyyy').format(date),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: context.getScreenWidth(2.3),
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: lineColor,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: spots.length <= 15,
                        getDotPainter: (spot, percent, bar, index) {
                          final isFirst = index == spots.length - 1;
                          return FlDotCirclePainter(
                            radius: isFirst ? 4 : 2.5,
                            color: isFirst ? lineColor : Colors.white,
                            strokeWidth: isFirst ? 2 : 1.5,
                            strokeColor: lineColor,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            lineColor.withOpacity(0.25),
                            lineColor.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _periodFilter(BuildContext context) {
    final periods = ['day', 'week', 'month', 'year'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ...periods.map((p) {
              return Obx(() {
                final isSelected = controller.activeFilterType == 'period' &&
                    controller.selectedPeriod == p;
                return Padding(
                  padding: EdgeInsets.only(right: context.getScreenWidth(2)),
                  child: GestureDetector(
                    onTap: () => controller.selectPeriod(p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: context.getScreenWidth(3),
                        vertical: context.getScreenHeight(0.8),
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryGold
                            : context.colorPalette.boxColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryGold
                              : context.colorPalette.subTitleColor.withOpacity(0.15),
                        ),
                      ),
                      child: Text(
                        p[0].toUpperCase() + p.substring(1),
                        style: TextStyle(
                          fontSize: context.getScreenWidth(3.2),
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : context.colorPalette.textColor,
                        ),
                      ),
                    ),
                  ),
                );
              });
            }),
            // Custom Range Chip
            Obx(() {
              final isCustom = controller.activeFilterType == 'custom';
              return GestureDetector(
                onTap: () async {
                  final result = await DateRangePickerSheet.show(
                    context,
                    initialStartDate: controller.selectedDateRange?.start,
                    initialEndDate: controller.selectedDateRange?.end,
                  );
                  if (result != null) {
                    controller.applyDateRange(
                      result.startDate,
                      result.endDate,
                      result.label,
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: context.getScreenWidth(3),
                    vertical: context.getScreenHeight(0.8),
                  ),
                  decoration: BoxDecoration(
                    color: isCustom
                        ? AppColors.primaryGold
                        : context.colorPalette.boxColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCustom
                          ? AppColors.primaryGold
                          : context.colorPalette.subTitleColor.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.date_range_rounded,
                        size: context.getScreenWidth(3),
                        color: isCustom
                            ? Colors.white
                            : context.colorPalette.textColor,
                      ),
                      SizedBox(width: context.getScreenWidth(1)),
                      Text(
                        'Custom',
                        style: TextStyle(
                          fontSize: context.getScreenWidth(3.2),
                          fontWeight: FontWeight.w600,
                          color: isCustom
                              ? Colors.white
                              : context.colorPalette.textColor,
                        ),
                      ),
                      if (isCustom) ...[
                        SizedBox(width: context.getScreenWidth(1)),
                        GestureDetector(
                          onTap: controller.clearDateRange,
                          child: Icon(
                            Icons.close_rounded,
                            size: context.getScreenWidth(2.8),
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
        // Date Range Label
        Obx(() {
          if (controller.activeFilterType != 'custom' ||
              controller.dateRangeLabel.isEmpty) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: EdgeInsets.only(top: context.getScreenHeight(1)),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: context.getScreenWidth(3),
                vertical: context.getScreenHeight(0.6),
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryGold.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: context.getScreenWidth(3),
                    color: AppColors.primaryGold,
                  ),
                  SizedBox(width: context.getScreenWidth(1.5)),
                  Expanded(
                    child: Text(
                      'Showing: ${controller.dateRangeLabel}',
                      style: TextStyle(
                        fontSize: context.getScreenWidth(2.8),
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryGoldDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _statisticsSummary(BuildContext context) {
    return Obx(() {
      final stats = controller.statistics;
      final statsState = controller.statisticsState;

      if (statsState == CurrentAppState.LOADING) {
        return Container(
          width: double.infinity,
          height: context.getScreenHeight(8),
          decoration: BoxDecoration(
            color: context.colorPalette.shimmerBaseColor,
            borderRadius: BorderRadius.circular(16),
          ),
        );
      }

      if (stats == null) return const SizedBox.shrink();

      final isUp = stats.change >= 0;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.getScreenWidth(4)),
        decoration: BoxDecoration(
          color: context.colorPalette.boxColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.colorPalette.subTitleColor.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: context.getScreenWidth(4.5),
                  color: isUp ? Colors.green : Colors.red,
                ),
                SizedBox(width: context.getScreenWidth(2)),
                Text(
                  stats.overallTrend,
                  style: TextStyle(
                    fontSize: context.getScreenWidth(3.2),
                    fontWeight: FontWeight.w700,
                    color: isUp ? Colors.green : Colors.red,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.getScreenWidth(2),
                    vertical: context.getScreenHeight(0.3),
                  ),
                  decoration: BoxDecoration(
                    color: isUp
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${isUp ? '+' : ''}${stats.changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: context.getScreenWidth(2.8),
                      fontWeight: FontWeight.w600,
                      color: isUp ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.getScreenHeight(1.5)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statItem(context, 'Low', '₹${stats.min.toStringAsFixed(0)}'),
                _statItem(context, 'Avg', '₹${stats.avg.toStringAsFixed(0)}'),
                _statItem(context, 'High', '₹${stats.max.toStringAsFixed(0)}'),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _statItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.getScreenWidth(2.5),
            color: context.colorPalette.subTitleColor,
          ),
        ),
        SizedBox(height: context.getScreenHeight(0.3)),
        Text(
          value,
          style: TextStyle(
            fontSize: context.getScreenWidth(3.5),
            fontWeight: FontWeight.w700,
            color: context.colorPalette.textColor,
          ),
        ),
      ],
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
              fontSize: context.getScreenWidth(3.5),
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
                    fontSize: context.getScreenWidth(3.8),
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
                  fontSize: context.getScreenWidth(3.2),
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
                    fontSize: context.getScreenWidth(3.5),
                    fontWeight: FontWeight.w600,
                    color: context.colorPalette.textColor,
                  ),
                ),
                if (rate.source != null)
                  Text(
                    'Set by ${rate.source}',
                    style: TextStyle(
                      fontSize: context.getScreenWidth(2.8),
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
                  fontSize: context.getScreenWidth(4.2),
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
                      const SizedBox(width: 2),
                      Text(
                        '₹${diff.abs().toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: context.getScreenWidth(2.5),
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

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.isNegative) return 'just now';
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM yyyy').format(dateTime);
  }
}
