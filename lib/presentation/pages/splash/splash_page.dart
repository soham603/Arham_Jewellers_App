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
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _dividerHeight;
  late Animation<double> _barProgress;
  bool _imagePrecached = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.23, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.23, curve: Curves.easeOutBack),
      ),
    );

    _dividerHeight = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.17, 0.34, curve: Curves.easeInOut),
      ),
    );

    _barProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.34, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagePrecached) {
      _imagePrecached = true;
      Future.wait([
        precacheImage(
          const AssetImage('assets/images/arham-logo.png'),
          context,
        ),
        precacheImage(
          const AssetImage('assets/images/ratnesh-logo.png'),
          context,
        ),
      ]).then((_) {
        _controller.forward();
        _initFlow();
      });
    }
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
        backgroundColor: palette.pageBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(6)),
            child: Column(
              children: [
              const Spacer(flex: 2),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoFade.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: child,
                    ),
                  );
                },
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: context.getScreenWidth(28),
                        height: context.getScreenWidth(28),
                        child: Image.asset(
                          'assets/images/arham-logo.png',
                          fit: BoxFit.contain,
                          color: context.colorPalette.goldDark,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Container(
                            width: 1,
                            height:
                                context.getScreenWidth(20) * _dividerHeight.value,
                            margin: EdgeInsets.symmetric(
                              horizontal: context.getScreenWidth(6),
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  context.colorPalette.gold.withOpacity(0.6),
                                  context.colorPalette.gold,
                                  context.colorPalette.gold.withOpacity(0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      LogoWidget(
                        logoSize: context.getScreenWidth(14),
                        iconColor: context.colorPalette.gold,
                        nameColor: context.colorPalette.goldDark,
                        nameFontSize: context.getScreenWidth(3.2),
                        nameLetterSpacing: 1,
                        subtitleColor: palette.subTitleColor,
                        subtitleFontSize: context.getScreenWidth(2.2),
                        iconNameSpacing: context.getScreenHeight(0.8),
                        nameSubtitleSpacing: context.getScreenHeight(0.5),
                      ),
                    ],
                  ),
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
                          context.getScreenWidth(100) * _barProgress.value,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFB8860B),
                            Color(0xFFD4AF37),
                            Color(0xFFB8860B),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: context.getScreenHeight(2)),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
