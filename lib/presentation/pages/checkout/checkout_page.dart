import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700)),
        leading: IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.arrow_back)),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Expanded(child: Divider(color: AppColors.primaryGold, thickness: 3)),
                SizedBox(width: 4),
                Expanded(child: Divider(color: Color(0xFFC8B79D), thickness: 3)),
                SizedBox(width: 4),
                Expanded(child: Divider(color: Color(0xFFC8B79D), thickness: 3)),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Address', style: TextStyle(fontSize: 12, color: AppColors.primaryGold)),
                  Text('Delivery', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Text('Payment', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            _section(
              title: 'Select Delivery Address',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  const Text('Home', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const Text('address', style: TextStyle(fontSize: 17, color: AppColors.textMuted)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE4DED4),
                        foregroundColor: AppColors.primaryGold,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {},
                      child: const Text('+ Add New Address', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text('Delivery Method', style: TextStyle(fontSize: 31, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 6),
            _radioGroup(
              children: const [
                _RadioTile(title: 'Home Delivery  •  Free  •  2-4 days', subtitle: ''),
                _RadioTile(title: 'Store Pickup  •  Free  •  Ready today', subtitle: '', selected: false),
              ],
            ),
            const SizedBox(height: 10),
            const Text('Payment Method', style: TextStyle(fontSize: 31, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 6),
            _radioGroup(
              children: const [
                _RadioTile(title: 'UPI', subtitle: 'GPay / PhonePe / Paytm'),
                _RadioTile(title: 'Card', subtitle: 'Debit or Credit Card', selected: false),
                _RadioTile(title: 'EMI', subtitle: '0% EMI available', selected: false),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {},
                child: const Text('Place Order  →', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _section({required String title, required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE3DDD5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 6),
        child,
      ],
    ),
  );
}

Widget _radioGroup({required List<Widget> children}) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE3DDD5)),
    ),
    child: Column(children: children),
  );
}

class _RadioTile extends StatelessWidget {
  const _RadioTile({required this.title, required this.subtitle, this.selected = true});

  final String title;
  final String subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.primaryGold : Colors.transparent,
              border: Border.all(color: selected ? AppColors.primaryGold : const Color(0xFFC1B7AA)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 20, color: AppColors.textDark)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: const TextStyle(fontSize: 16, color: AppColors.textMuted)),
                const Divider(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
