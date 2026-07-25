import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  static Future<void> launchWhatsApp(
    BuildContext context,
    String phone, {
    String? message,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final encodedMessage = message != null && message.isNotEmpty
        ? Uri.encodeComponent(message)
        : null;

    final whatsappUri = Uri.parse(
      'whatsapp://send?phone=$cleanPhone${encodedMessage != null ? '&text=$encodedMessage' : ''}',
    );
    final whatsappBusinessUri = Uri.parse(
      'whatsapp-business://send?phone=$cleanPhone${encodedMessage != null ? '&text=$encodedMessage' : ''}',
    );
    final webUri = buildUrl(phone, message: message);

    final hasWhatsapp = await canLaunchUrl(whatsappUri);
    final hasWhatsappBusiness = await canLaunchUrl(whatsappBusinessUri);

    if (hasWhatsapp && hasWhatsappBusiness) {
      await _showWhatsAppPicker(
        context,
        whatsappUri: whatsappUri,
        whatsappBusinessUri: whatsappBusinessUri,
        webUri: webUri,
      );
    } else if (hasWhatsapp) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else if (hasWhatsappBusiness) {
      await launchUrl(whatsappBusinessUri, mode: LaunchMode.externalApplication);
    } else {
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  static Future<void> _showWhatsAppPicker(
    BuildContext context, {
    required Uri whatsappUri,
    required Uri whatsappBusinessUri,
    required Uri webUri,
  }) async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Open with',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.chat,
                color: Color(0xFF25D366),
              ),
              title: const Text('WhatsApp'),
              onTap: () async {
                Navigator.pop(ctx);
                await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.business,
                color: Color(0xFF25D366),
              ),
              title: const Text('WhatsApp Business'),
              onTap: () async {
                Navigator.pop(ctx);
                await launchUrl(whatsappBusinessUri, mode: LaunchMode.externalApplication);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.language,
                color: Color(0xFF25D366),
              ),
              title: const Text('Web Browser'),
              onTap: () async {
                Navigator.pop(ctx);
                await launchUrl(webUri, mode: LaunchMode.externalApplication);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
