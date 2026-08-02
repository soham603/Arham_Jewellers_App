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
