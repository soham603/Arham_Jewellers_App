import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/SessionManager.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import '../../../core/widgets/logo_widget.dart';

import '../../../app/routes/app_routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _storage = FlutterSecureStorage();

  late AnimationController _controller;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _dividerHeight;
  late Animation<double> _barProgress;
  bool _imagePrecached = false;

  Size? _screenSize;

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
          const AssetImage('assets/images/arham-logo-opt.webp'),
          context,
        ),
        precacheImage(
          const AssetImage('assets/images/ratnesh-logo-opt.webp'),
          context,
        ),
      ]).then((_) {
        _initFlow();
      });
    }
  }

  Future<void> _initFlow() async {
    _controller.forward();
    final routeFuture = _determineTargetRoute();
    await Future.delayed(const Duration(seconds: 4));
    final targetRoute = await routeFuture;
    Get.offNamed(targetRoute);
  }

  Future<String> _determineTargetRoute() async {
    try {
      final all = await _storage.readAll();
      final token = all[DatabaseKeyConstants.ACCESS_TOKEN];
      if (token == null || token.isEmpty) {
        return AppRoutes.login;
      }

      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final accessExpiry = int.tryParse(
        all[DatabaseKeyConstants.ACCESS_TOKEN_EXPIRY] ?? '',
      );
      final refreshExpiry = int.tryParse(
        all[DatabaseKeyConstants.REFRESH_TOKEN_EXPIRY] ?? '',
      );

      if (accessExpiry != null && now < accessExpiry) {
        return AppRoutes.home;
      }

      if (refreshExpiry != null && now < refreshExpiry) {
        final refreshed = await baseHttpService.proactiveTokenRefresh();
        return refreshed ? AppRoutes.home : AppRoutes.login;
      }

      return AppRoutes.login;
    } catch (e, stackTrace) {
      return AppRoutes.login;
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
    final size = _screenSize ??= MediaQuery.of(context).size;

    final horizontalPadding = size.width * 0.06;
    final logoBox = size.width * 0.28;
    final dividerBox = size.width * 0.20;
    final dividerSpacing = size.width * 0.06;
    final barHeight = size.height * 0.005;
    final barWidthBase = size.width;
    final logoNameSize = size.width * 0.18;
    final nameFontSize = size.width * 0.03;
    final subtitleFontSize = size.width * 0.022;
    final iconNameSpacing = size.height * 0.008;
    final nameSubtitleSpacing = size.height * 0.005;
    final topGap = size.height * 0.01;
    final bottomGap = size.height * 0.02;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
        backgroundColor: palette.pageBackgroundColor,
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                        width: logoBox,
                        height: logoBox,
                        child: Image.asset(
                          'assets/images/arham-logo-opt.webp',
                          fit: BoxFit.contain,
                          color: palette.goldDark,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Container(
                            width: 1,
                            height: dividerBox * _dividerHeight.value,
                            margin: EdgeInsets.symmetric(
                              horizontal: dividerSpacing,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  palette.gold.withValues(alpha: 0.6),
                                  palette.gold,
                                  palette.gold.withValues(alpha: 0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      LogoWidget(
                        logoSize: logoNameSize,
                        iconColor: palette.gold,
                        nameColor: palette.goldDark,
                        nameFontSize: nameFontSize,
                        nameLetterSpacing: 1,
                        subtitleColor: palette.subTitleColor,
                        subtitleFontSize: subtitleFontSize,
                        iconNameSpacing: iconNameSpacing,
                        nameSubtitleSpacing: nameSubtitleSpacing,
                        showSubtitle: false,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(height: topGap),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: barHeight,
                      width: barWidthBase * _barProgress.value,
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
              SizedBox(height: bottomGap),
            ],
          ),
        ),
      ),
    );
  }
}
