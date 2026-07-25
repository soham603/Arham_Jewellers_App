import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/admin_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_text_field.dart';
import '../../../core/widgets/country_code_prefix.dart';
import '../../../core/widgets/logo_widget.dart';
import '../../../presentation/controllers/AuthController.dart';
import '../../../utils/Enums.dart';
import '../../../utils/whatsapp_util.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final AuthController authController = Get.put(AuthController());
  final TextEditingController phoneController = TextEditingController();
  bool _isFormValid = false;

  void _validateForm() {
    setState(() {
      _isFormValid = phoneController.text.trim().isNotEmpty &&
          phoneController.text.trim().length >= 10;
    });
  }

  @override
  void initState() {
    super.initState();
    phoneController.addListener(_validateForm);
  }

  @override
  void dispose() {
    phoneController.removeListener(_validateForm);
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _launchWhatsApp() async {
    final phone = await AdminConstants.adminPhoneAsync;
    final uri = WhatsAppUtil.buildUrl(
      phone,
      message: 'Hi, I have forgotten my password. Please help me reset it.',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
            size: context.getResponsiveSize(5),
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: context.getResponsiveSize(5),
            vertical: context.heightPercent(1),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: context.heightPercent(0.2)),

                    // ── Logo ──
                    Center(
                      child: LogoWidget(
                        logoSize: context.getResponsiveSize(16),
                        nameFontSize: context.getResponsiveSize(4),
                        subtitleFontSize: context.getResponsiveSize(2),
                        iconColor: context.colorPalette.gold,
                        nameColor: context.colorPalette.goldDeep,
                        subtitleColor: context.colorPalette.goldDark,
                        nameLetterSpacing: 2.0,
                        iconNameSpacing: context.heightPercent(0.8),
                        nameSubtitleSpacing: context.heightPercent(0.2),
                      ),
                    ),

                    SizedBox(height: context.heightPercent(5)),

                    // ── Title ──
                    Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: context.getResponsiveSize(5.5),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),

                    SizedBox(height: context.heightPercent(1)),

                    // ── Subtitle ──
                    Text(
                      "No worries! Enter your registered mobile number and we'll contact you with new password.",
                      style: TextStyle(
                        fontSize: context.getResponsiveSize(3.3),
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: context.heightPercent(4)),

                    // ── Phone Input ──
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Mobile Number',
                        style: TextStyle(
                          fontSize: context.getResponsiveSize(3.2),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),

                    SizedBox(height: context.heightPercent(0.8)),

                    AnimatedTextField(
                      controller: phoneController,
                      hintText: 'Enter Mobile Number',
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      prefixIcon: const CountryCodePrefix(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Phone number is required";
                        }
                        if (value.trim().length < 10) {
                          return "Enter valid phone number";
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: context.heightPercent(1.5)),

                    // ── Send Reset Link Button ──
                    Obx(() {
                      final isLoading =
                          authController.forgotPasswordState == CurrentAppState.LOADING;

                      return SizedBox(
                        width: double.infinity,
                        height: context.heightPercent(6),
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.disabled)) {
                                return AppColors.primaryGold.withValues(alpha: 0.35);
                              }
                              return AppColors.primaryGold;
                            }),
                            elevation: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.disabled)) {
                                return 0;
                              }
                              return 2;
                            }),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  context.getResponsiveSize(2.5),
                                ),
                              ),
                            ),
                          ),
                          onPressed: (!_isFormValid || isLoading)
                              ? null
                              : () async {
                                  final fullPhoneNumber =
                                      '+91${phoneController.text.trim()}';
                                  await authController.forgotPassword(
                                    phoneNumber: fullPhoneNumber,
                                    context: context,
                                    onSuccess: () {
                                      phoneController.clear();
                                    },
                                  );
                                },
                          child: isLoading
                              ? SizedBox(
                                  height: context.getResponsiveSize(5),
                                  width: context.getResponsiveSize(5),
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Send Reset Link',
                                  style: TextStyle(
                                    fontSize: context.getResponsiveSize(4.5),
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      );
                    }),

                    SizedBox(height: context.heightPercent(2.5)),

                    // ── OR Divider ──
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppColors.primaryGold.withValues(alpha: 0.4),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.getResponsiveSize(3),
                          ),
                          child: Text(
                            'or',
                            style: TextStyle(
                              fontSize: context.getResponsiveSize(3.2),
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryGold.withValues(alpha: 0.4),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: context.heightPercent(2.5)),

                    // ── Back to Sign In ──
                    SizedBox(
                      width: double.infinity,
                      height: context.heightPercent(6),
                      child: OutlinedButton(
                        style: ButtonStyle(
                          side: WidgetStateProperty.all(
                            BorderSide(color: AppColors.primaryGold),
                          ),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                context.getResponsiveSize(2.5),
                              ),
                            ),
                          ),
                        ),
                        onPressed: () => Get.toNamed(AppRoutes.login),
                        child: Text(
                          'Back to Sign In',
                          style: TextStyle(
                            fontSize: context.getResponsiveSize(4.5),
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: context.heightPercent(6)),

                    // ── Support Section ──
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: 'Need help? ',
                          style: TextStyle(
                            fontSize: context.getResponsiveSize(3.2),
                            color: AppColors.textMuted,
                          ),
                          children: [
                            TextSpan(
                              text: 'Contact Us',
                              style: TextStyle(
                                color: AppColors.primaryGold,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = _launchWhatsApp,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: context.heightPercent(2)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }
}
