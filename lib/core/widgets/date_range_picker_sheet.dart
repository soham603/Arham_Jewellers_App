import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class DateRangeResult {
  final DateTime startDate;
  final DateTime endDate;
  final String label;

  const DateRangeResult({
    required this.startDate,
    required this.endDate,
    required this.label,
  });
}

class DateRangePickerSheet extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const DateRangePickerSheet({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
  });

  static Future<DateRangeResult?> show(
    BuildContext context, {
    DateTime? initialStartDate,
    DateTime? initialEndDate,
  }) {
    return showModalBottomSheet<DateRangeResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DateRangePickerSheet(
        initialStartDate: initialStartDate,
        initialEndDate: initialEndDate,
      ),
    );
  }

  @override
  State<DateRangePickerSheet> createState() => _DateRangePickerSheetState();
}

class _DateRangePickerSheetState extends State<DateRangePickerSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedPreset;

  final ScrollController _monthScrollController = ScrollController();
  final ScrollController _yearScrollController = ScrollController();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  late final List<int> _years;
  int? _selectedMonth;
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _years = List.generate(7, (i) => now.year - 3 + i);
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    if (_startDate != null) {
      _selectedMonth = _startDate!.month;
      _selectedYear = _startDate!.year;
    }
  }

  @override
  void dispose() {
    _monthScrollController.dispose();
    _yearScrollController.dispose();
    super.dispose();
  }

  void _applyPreset(String preset) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (preset) {
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'Last 3 Months':
        start = DateTime(now.year, now.month - 2, 1);
        break;
      case 'Last 6 Months':
        start = DateTime(now.year, now.month - 5, 1);
        break;
      case 'This Year':
        start = DateTime(now.year, 1, 1);
        break;
      case 'Last Year':
        start = DateTime(now.year - 1, 1, 1);
        end = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        break;
      default:
        return;
    }

    setState(() {
      _selectedPreset = preset;
      _startDate = start;
      _endDate = end;
      _selectedMonth = null;
      _selectedYear = null;
    });
  }

  void _applyMonthYear(int month, int year) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final monthName = _months[month - 1];

    setState(() {
      _selectedPreset = '$monthName $year';
      _startDate = start;
      _endDate = end;
      _selectedMonth = month;
      _selectedYear = year;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedPreset = null;
      _startDate = null;
      _endDate = null;
      _selectedMonth = null;
      _selectedYear = null;
    });
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(2020),
      lastDate: _endDate ?? now,
      helpText: 'SELECT START DATE',
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
            headerHelpStyle: TextStyle(fontSize: ctx.responsiveFont(13)),
            dayStyle: TextStyle(fontSize: ctx.responsiveFont(14)),
            weekdayStyle: TextStyle(fontSize: ctx.responsiveFont(12)),
            dayShape: WidgetStateProperty.all(const CircleBorder()),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        _selectedPreset = null;
        _selectedMonth = null;
        _selectedYear = null;
        if (_endDate != null && picked.isAfter(_endDate!)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate: _startDate ?? DateTime(2020),
      lastDate: now,
      helpText: 'SELECT END DATE',
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
            headerHelpStyle: TextStyle(fontSize: ctx.responsiveFont(13)),
            dayStyle: TextStyle(fontSize: ctx.responsiveFont(14)),
            weekdayStyle: TextStyle(fontSize: ctx.responsiveFont(12)),
            dayShape: WidgetStateProperty.all(const CircleBorder()),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        _selectedPreset = null;
        _selectedMonth = null;
        _selectedYear = null;
      });
    }
  }

  void _apply() {
    if (_startDate == null || _endDate == null) return;

    final label = _selectedPreset ??
        '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}';

    Navigator.of(context).pop(DateRangeResult(
      startDate: _startDate!,
      endDate: _endDate!,
      label: label,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.responsiveWidth(24, tabletVal: 28)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPresetSection(),
                  _buildMonthYearSection(),
                  _buildCustomDateSection(),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        width: context.responsiveWidth(40, tabletVal: 48),
        height: context.responsiveWidth(4, tabletVal: 5),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.responsiveWidth(24, tabletVal: 28),
        context.responsiveWidth(16, tabletVal: 20),
        context.responsiveWidth(24, tabletVal: 28),
        context.responsiveWidth(8, tabletVal: 10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.date_range_rounded,
            color: AppColors.primaryGold,
            size: context.responsiveWidth(22, tabletVal: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Select Date Range',
              style: TextStyle(
                fontSize: context.responsiveFont(18),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          if (_startDate != null || _selectedPreset != null)
            GestureDetector(
              onTap: _clearSelection,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsiveWidth(10, tabletVal: 12),
                  vertical: context.responsiveWidth(5, tabletVal: 6),
                ),
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: context.responsiveFont(12),
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPresetSection() {
    final presets = ['This Month', 'Last 3 Months', 'Last 6 Months', 'This Year', 'Last Year'];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.responsiveWidth(24, tabletVal: 28),
        context.responsiveWidth(8, tabletVal: 10),
        context.responsiveWidth(24, tabletVal: 28),
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Quick Select'),
          const SizedBox(height: 8),
          SizedBox(
            height: context.responsiveWidth(38, tabletVal: 42),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: presets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final preset = presets[index];
                final isSelected = _selectedPreset == preset;
                return GestureDetector(
                  onTap: () => _applyPreset(preset),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsiveWidth(16, tabletVal: 20),
                      vertical: context.responsiveWidth(8, tabletVal: 10),
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryGold : AppColors.tileBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryGold : AppColors.divider,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      preset,
                      style: TextStyle(
                        fontSize: context.responsiveFont(13),
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthYearSection() {
    final now = DateTime.now();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.responsiveWidth(24, tabletVal: 28),
        context.responsiveWidth(20, tabletVal: 24),
        context.responsiveWidth(24, tabletVal: 28),
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Select Month'),
          const SizedBox(height: 8),
          SizedBox(
            height: context.responsiveWidth(36, tabletVal: 40),
            child: ListView.separated(
              controller: _monthScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _months.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final monthNum = index + 1;
                final isSelected = _selectedMonth == monthNum && _selectedYear != null;
                return GestureDetector(
                  onTap: _selectedYear != null
                      ? () => _applyMonthYear(monthNum, _selectedYear!)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: context.responsiveWidth(42, tabletVal: 48),
                    height: context.responsiveWidth(36, tabletVal: 40),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryGold
                          : (monthNum <= now.month || _selectedYear != now.year
                              ? AppColors.tileBg
                              : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryGold : AppColors.divider,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _months[index],
                      style: TextStyle(
                        fontSize: context.responsiveFont(11),
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (monthNum <= now.month || _selectedYear != now.year
                                ? AppColors.textDark
                                : Colors.grey),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _sectionLabel('Select Year'),
          const SizedBox(height: 8),
          SizedBox(
            height: context.responsiveWidth(36, tabletVal: 40),
            child: ListView.separated(
              controller: _yearScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _years.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final year = _years[index];
                final isSelected = _selectedYear == year;
                final isFuture = year > now.year;
                return GestureDetector(
                  onTap: isFuture ? null : () => setState(() => _selectedYear = year),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsiveWidth(16, tabletVal: 20),
                    ),
                    height: context.responsiveWidth(36, tabletVal: 40),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryGold
                          : (isFuture ? Colors.grey.shade100 : AppColors.tileBg),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryGold : AppColors.divider,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$year',
                      style: TextStyle(
                        fontSize: context.responsiveFont(13),
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isFuture ? Colors.grey : AppColors.textDark),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDateSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.responsiveWidth(24, tabletVal: 28),
        context.responsiveWidth(20, tabletVal: 24),
        context.responsiveWidth(24, tabletVal: 28),
        context.responsiveWidth(8, tabletVal: 10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Or Pick Custom Dates'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _dateField('Start Date', _startDate, _pickStartDate)),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsiveWidth(12, tabletVal: 14),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primaryGold,
                  size: context.responsiveWidth(20, tabletVal: 22),
                ),
              ),
              Expanded(child: _dateField('End Date', _endDate, _pickEndDate)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateField(String label, DateTime? date, VoidCallback onTap) {
    final hasDate = date != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: context.responsiveWidth(14, tabletVal: 16),
          vertical: context.responsiveWidth(12, tabletVal: 14),
        ),
        decoration: BoxDecoration(
          color: hasDate ? AppColors.primaryGold.withValues(alpha: 0.06) : AppColors.tileBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasDate ? AppColors.primaryGold : AppColors.divider,
            width: hasDate ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: context.responsiveFont(11),
                fontWeight: FontWeight.w500,
                color: hasDate ? AppColors.primaryGold : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasDate ? DateFormat('dd MMM yyyy').format(date) : 'Tap to select',
              style: TextStyle(
                fontSize: context.responsiveFont(13),
                fontWeight: hasDate ? FontWeight.w600 : FontWeight.w400,
                color: hasDate ? AppColors.textDark : AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: context.responsiveFont(12),
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildFooter() {
    final canApply = _startDate != null && _endDate != null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.responsiveWidth(24, tabletVal: 28),
        context.responsiveWidth(12, tabletVal: 14),
        context.responsiveWidth(24, tabletVal: 28),
        context.responsiveWidth(16, tabletVal: 20),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider.withValues(alpha: 0.5))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _clearSelection,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: context.responsiveWidth(14, tabletVal: 16),
                  ),
                ),
                child: Text(
                  'Clear',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: canApply ? _apply : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  disabledBackgroundColor: AppColors.primaryGold.withValues(alpha: 0.4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: context.responsiveWidth(14, tabletVal: 16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Apply Range',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: context.responsiveFont(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


