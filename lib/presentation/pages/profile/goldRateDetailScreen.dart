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
              _statisticsSummary(context),
              SizedBox(height: context.heightPercent(2.5)),
              _graphPlaceholder(context),
              SizedBox(height: context.heightPercent(3)),
              _periodFilter(context),
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

  Widget _graphPlaceholder(BuildContext context) {
    return Obx(() {
      final history = controller.history;
      final histState = controller.historyState;

      if (histState == CurrentAppState.LOADING && history.isEmpty) {
        return Container(
          width: double.infinity,
          height: context.heightPercent(22),
          decoration: BoxDecoration(
            color: context.colorPalette.shimmerBaseColor,
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }

      if (history.length < 2) {
        return Container(
          width: double.infinity,
          height: context.heightPercent(20),
          decoration: BoxDecoration(
            color: context.colorPalette.boxColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: context.colorPalette.subTitleColor.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart_rounded,
                size: context.getResponsiveSize(12),
                color: context.colorPalette.subTitleColor.withValues(alpha: 0.4),
              ),
              SizedBox(height: context.heightPercent(1)),
              Text(
                'Need at least 2 data points for graph',
                style: TextStyle(
                  fontSize: context.getResponsiveSize(3.5),
                  color: context.colorPalette.subTitleColor.withValues(alpha: 0.6),
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
      
      final rangeY = maxY - minY;
      final stepY = rangeY > 0 ? (rangeY / 3).ceilToDouble() : 500.0;
      final padding = stepY * 0.15;
      
      final lineColor = AppColors.primaryGold;

      return Container(
        width: double.infinity,
        height: context.heightPercent(25),
        padding: EdgeInsets.fromLTRB(
          context.getResponsiveSize(2),
          context.heightPercent(2.5),
          context.getResponsiveSize(4),
          context.heightPercent(1.5),
        ),
        decoration: BoxDecoration(
          color: context.colorPalette.boxColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.colorPalette.subTitleColor.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: context.getResponsiveSize(2.5)),
              child: Text(
                'Gold Price Graph',
                style: TextStyle(
                  fontSize: context.getResponsiveSize(4),
                  fontWeight: FontWeight.w600,
                  color: context.colorPalette.textColor,
                ),
              ),
            ),
            SizedBox(height: context.heightPercent(1.5)),
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
                    horizontalInterval: stepY,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: context.colorPalette.subTitleColor.withValues(alpha: 0.08),
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
                        reservedSize: context.getResponsiveSize(13), 
                        interval: stepY,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              '₹${(value / 1000).toStringAsFixed(0)}k',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: context.getResponsiveSize(2.6),
                                fontWeight: FontWeight.w500,
                                color: context.colorPalette.subTitleColor.withValues(alpha: 0.7),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: context.heightPercent(3),
                        interval: spots.length > 7
                            ? (spots.length / 5).ceilToDouble()
                            : 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= sorted.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: EdgeInsets.only(
                              top: context.heightPercent(0.8),
                            ),
                            child: Text(
                              DateFormat('dd MMM').format(
                                sorted[idx].timestamp.toLocal(),
                              ),
                              style: TextStyle(
                                fontSize: context.getResponsiveSize(2.2),
                                color: context.colorPalette.subTitleColor
                                    .withValues(alpha: 0.6),
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
                        horizontal: context.getResponsiveSize(3),
                        vertical: context.heightPercent(0.8),
                      ),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final date = sorted[spot.x.toInt()].timestamp.toLocal();
                          return LineTooltipItem(
                            '₹${spot.y.toStringAsFixed(0)}\n',
                            TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: context.getResponsiveSize(3),
                            ),
                            children: [
                              TextSpan(
                                text: DateFormat('dd MMM yyyy').format(date),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: context.getResponsiveSize(2.3),
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
                            lineColor.withValues(alpha: 0.25),
                            lineColor.withValues(alpha: 0.0),
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
    final Map<String, String> periodLabels = {
      'day': 'Day',
      'week': 'Week',
      'month': 'Month',
      'year': 'Year',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              ...periodLabels.keys.map((p) {
                final displayLabel = periodLabels[p]!;
                return Obx(() {
                  final isSelected = controller.activeFilterType == 'period' &&
                      controller.selectedPeriod == p;
                  return Padding(
                    padding: EdgeInsets.only(right: context.getResponsiveSize(2)),
                    child: GestureDetector(
                      onTap: () => controller.selectPeriod(p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(
                          horizontal: context.getResponsiveSize(3.5),
                          vertical: context.heightPercent(1),
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryGold
                              : context.colorPalette.boxColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryGold
                                : context.colorPalette.subTitleColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          displayLabel,
                          style: TextStyle(
                            fontSize: context.getResponsiveSize(3.2),
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
                      horizontal: context.getResponsiveSize(3.5),
                      vertical: context.heightPercent(1),
                    ),
                    decoration: BoxDecoration(
                      color: isCustom
                          ? AppColors.primaryGold
                          : context.colorPalette.boxColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCustom
                            ? AppColors.primaryGold
                            : context.colorPalette.subTitleColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.date_range_rounded,
                          size: context.getResponsiveSize(3.5),
                          color: isCustom
                              ? Colors.white
                              : context.colorPalette.textColor,
                        ),
                        SizedBox(width: context.getResponsiveSize(1.5)),
                        Text(
                          'Custom',
                          style: TextStyle(
                            fontSize: context.getResponsiveSize(3.2),
                            fontWeight: FontWeight.w600,
                            color: isCustom
                                ? Colors.white
                                : context.colorPalette.textColor,
                          ),
                        ),
                        if (isCustom) ...[
                          SizedBox(width: context.getResponsiveSize(1.5)),
                          GestureDetector(
                            onTap: controller.clearDateRange,
                            child: Icon(
                              Icons.close_rounded,
                              size: context.getResponsiveSize(3.2),
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
        ),
        Obx(() {
          if (controller.activeFilterType != 'custom' ||
              controller.dateRangeLabel.isEmpty) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: EdgeInsets.only(top: context.heightPercent(1.5)),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: context.getResponsiveSize(3.5),
                vertical: context.heightPercent(1),
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryGold.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: context.getResponsiveSize(3.5),
                    color: AppColors.primaryGold,
                  ),
                  SizedBox(width: context.getResponsiveSize(2)),
                  Expanded(
                    child: Text(
                      'Showing: ${controller.dateRangeLabel}',
                      style: TextStyle(
                        fontSize: context.getResponsiveSize(3),
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

  Widget _statisticsSummary(BuildContext context) {
    return Obx(() {
      final stats = controller.statistics;
      final statsState = controller.statisticsState;

      if (statsState == CurrentAppState.LOADING) {
        return Container(
          width: double.infinity,
          height: context.heightPercent(15),
          decoration: BoxDecoration(
            color: context.colorPalette.shimmerBaseColor,
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }

      if (stats == null) return const SizedBox.shrink();

      final isUp = stats.change >= 0;
      final trendColor = isUp ? Colors.green.shade600 : Colors.red.shade600;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.getResponsiveSize(5)),
        decoration: BoxDecoration(
          color: context.colorPalette.boxColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.colorPalette.subTitleColor.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Market Trend",
                      style: TextStyle(
                        fontSize: context.getResponsiveSize(3.2),
                        color: context.colorPalette.subTitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: context.heightPercent(0.5)),
                    Row(
                      children: [
                        Icon(
                          isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: context.getResponsiveSize(5),
                          color: trendColor,
                        ),
                        SizedBox(width: context.getResponsiveSize(1.5)),
                        Text(
                          stats.overallTrend.toUpperCase(),
                          style: TextStyle(
                            fontSize: context.getResponsiveSize(4.5),
                            fontWeight: FontWeight.w800,
                            color: trendColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.getResponsiveSize(3.5),
                    vertical: context.heightPercent(0.8),
                  ),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${isUp ? '+' : ''}${stats.changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.5),
                      fontWeight: FontWeight.w700,
                      color: trendColor,
                    ),
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: EdgeInsets.symmetric(vertical: context.heightPercent(1.5)),
              child: Divider(
                color: context.colorPalette.subTitleColor.withValues(alpha: 0.15),
                thickness: 1,
              ),
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCol(context, 'Low', stats.min, Icons.south_east_rounded, Colors.redAccent),
                _buildStatCol(context, 'Avg', stats.avg, Icons.horizontal_rule_rounded, Colors.orangeAccent),
                _buildStatCol(context, 'High', stats.max, Icons.north_east_rounded, Colors.green),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCol(BuildContext context, String label, double value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: context.getResponsiveSize(3), color: color),
            SizedBox(width: context.getResponsiveSize(1)),
            Text(
              label,
              style: TextStyle(
                fontSize: context.getResponsiveSize(3),
                color: context.colorPalette.subTitleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: context.heightPercent(0.6)),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: context.getResponsiveSize(3.8),
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
                      const SizedBox(width: 2),
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