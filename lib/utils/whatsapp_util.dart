class WhatsAppUtil {
  WhatsAppUtil._();

  static Uri buildUrl(String phone, {String? message}) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (message != null && message.isNotEmpty) {
      return Uri.parse(
        'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
      );
    }
    return Uri.parse('https://wa.me/$cleanPhone');
  }
}
