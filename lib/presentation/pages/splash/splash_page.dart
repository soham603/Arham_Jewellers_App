import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/utils/SessionManager.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/logo_widget.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  final SessionManager sessionManager = SessionManager();

  late AnimationController _controller;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _widthAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
    _initFlow();
  }

  Future<void> _initFlow() async {
    final stopwatch = Stopwatch()..start();

    final token = await sessionManager.getAccessToken();
    final isExpired = await sessionManager.isAccessTokenExpired();

    final elapsed = stopwatch.elapsedMilliseconds;
    final remaining = 3500 - elapsed;

    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }

    if (token != null && !isExpired) {
      Get.offNamed(AppRoutes.home);
    } else {
      Get.offNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;

    return Scaffold(
      backgroundColor: palette.pageBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.getScreenWidth(6),
          ),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Center(
                child: LogoWidget(
                  size: context.getScreenWidth(55),
                ),
              ),
              SizedBox(height: context.getScreenHeight(3)),
              Text(
                'RATNESHGOLD',
                style: TextStyle(
                  fontSize: context.getScreenWidth(7),
                  fontWeight: FontWeight.w700,
                  color: palette.textColor,
                ),
              ),
              const Spacer(flex: 3),
              Text(
                'Purity  •  Quality  •  Trust',
                style: TextStyle(
                  fontSize: context.getScreenWidth(3.8),
                  color: palette.subTitleColor,
                ),
              ),
              SizedBox(height: context.getScreenHeight(1)),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: context.getScreenHeight(0.5),
                      width: context.getScreenWidth(100) *
                          _widthAnimation.value,
                      color: const Color(0xFFD3C6B5),
                    ),
                  );
                },
              ),
              SizedBox(height: context.getScreenHeight(2)),
            ],
          ),
        ),
      ),
    );
  }
}