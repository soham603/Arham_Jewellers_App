import 'package:flutter/material.dart';

class MobileFrame extends StatelessWidget {
  const MobileFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 430) {
          return child;
        }

        return Container(
          color: const Color(0xFFDFDFDF),
          alignment: Alignment.center,
          child: Container(
            width: 360,
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
    );
  }
}
