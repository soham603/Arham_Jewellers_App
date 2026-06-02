import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/utils/SessionManager.dart';
import '../../../core/widgets/logo_widget.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

import '../../../app/routes/app_routes.dart';

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
    final isAccessExpired = await sessionManager.isAccessTokenExpired();
    final isRefreshExpired = await sessionManager.isRefreshTokenExpired();

    final elapsed = stopwatch.elapsedMilliseconds;
    final remaining = 3500 - elapsed;

    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }

    if (token != null && (!isAccessExpired || !isRefreshExpired)) {
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
          padding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(6)),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Center(
                child: LogoWidget(
                  logoSize: context.getScreenWidth(48),
                  iconColor: context.colorPalette.gold,
                  nameColor: context.colorPalette.goldDeep,
                  nameFontSize: context.getScreenWidth(7),
                  nameLetterSpacing: 2,
                  subtitleColor: palette.subTitleColor,
                  subtitleFontSize: context.getScreenWidth(3.8),
                  iconNameSpacing: context.getScreenHeight(3),
                  nameSubtitleSpacing: context.getScreenHeight(1.5),
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(height: context.getScreenHeight(1)),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: context.getScreenHeight(0.5),
                      width:
                          context.getScreenWidth(100) * _widthAnimation.value,
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
