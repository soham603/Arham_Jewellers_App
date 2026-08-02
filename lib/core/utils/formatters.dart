import 'package:intl/intl.dart';

String formatIndianPrice(double value) {
  final String valueStr = value.toInt().toString();
  if (valueStr.length <= 3) return valueStr;

  String result = valueStr.substring(valueStr.length - 3);
  String remaining = valueStr.substring(0, valueStr.length - 3);

  while (remaining.length > 2) {
    result = '${remaining.substring(remaining.length - 2)},$result';
    remaining = remaining.substring(0, remaining.length - 2);
  }

  return remaining.isEmpty ? result : '$remaining,$result';
}

String formatCompactAmount(double amount) {
  if (amount < 1000) return amount.toInt().toString();
  if (amount < 100000) return formatIndianPrice(amount);
  if (amount < 10000000) {
    final double lakhs = amount / 100000;
    return '${lakhs.toStringAsFixed(1)}L';
  }
  final double crores = amount / 10000000;
  return '${crores.toStringAsFixed(1)}Cr';
}

String formatOrderDate(DateTime date) {
  return DateFormat('d MMM yyyy').format(date);
}

String formatOrderDateTime(DateTime date) {
  return DateFormat('dd MMM yyyy • hh:mm a').format(date);
}

String formatPrice(double value) {
  return '₹${formatIndianPrice(value)}';
}

String formatAmount(double value, {int decimals = 0}) {
  return '₹${value.toStringAsFixed(decimals)}';
}

String formatDate(DateTime date, {String pattern = 'dd MMM yyyy'}) {
  return DateFormat(pattern).format(date);
}

String? formatWeight(Object? value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty || raw.toLowerCase() == 'null') {
    return null;
  }
  final parsed = num.tryParse(raw);
  if (parsed == null) return raw;
  if (parsed == parsed.roundToDouble()) return parsed.toInt().toString();
  return parsed.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}
