import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/services/deviceIdService.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import '../../../core/constants/admin_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_text_field.dart';
import '../../../core/widgets/logo_widget.dart';
import '../../../presentation/controllers/AuthController.dart';
import '../../../utils/ToastUtil.dart';
import '../../../utils/whatsapp_util.dart';

class ChangeHandsetPage extends StatefulWidget {
  const ChangeHandsetPage({super.key});

  @override
  State<ChangeHandsetPage> createState() => _ChangeHandsetPageState();
}

class _ChangeHandsetPageState extends State<ChangeHandsetPage> {
  final AuthController authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isFormValid = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String selectedCountryCode = "+91";

  void validateForm() {
    setState(() {
      isFormValid =
          phoneController.text.trim().isNotEmpty &&
          passwordController.text.trim().isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    phoneController.addListener(validateForm);
    passwordController.addListener(validateForm);
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _launchWhatsApp() async {
    final uri = WhatsAppUtil.buildUrl(
      AdminConstants.adminPhone,
      message: 'Hi, I need help changing my handset. Please assist me.',
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
              child: Form(
                key: _formKey,
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
                        'Change Handset',
                        style: TextStyle(
                          fontSize: context.getResponsiveSize(5.5),
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),

                      SizedBox(height: context.heightPercent(1)),

                      // ── Subtitle ──
                      Text(
                        'Verify your identity to link this new device to your account securely.',
                        style: TextStyle(
                          fontSize: context.getResponsiveSize(3.3),
                          color: AppColors.textMuted,
                          height: 1.5,
                        ),
                      ),

                      SizedBox(height: context.heightPercent(4)),

                      // ── Mobile Number Label ──
                      Text(
                        'Registered Mobile Number',
                        style: TextStyle(
                          fontSize: context.getResponsiveSize(3.2),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),

                      SizedBox(height: context.heightPercent(0.8)),

                      // ── Phone Input ──
                      AnimatedTextField(
                        controller: phoneController,
                        hintText: 'Registered Mobile Number',
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        prefixIcon: CountryCodePicker(
                          onChanged: (countryCode) {
                            setState(() {
                              selectedCountryCode = countryCode.dialCode ?? "+91";
                            });
                          },
                          initialSelection: 'IN',
                          favorite: const ['+91', 'IN'],
                          showCountryOnly: false,
                          showOnlyCountryWhenClosed: false,
                          showDropDownButton: false,
                          showFlag: false,
                          alignLeft: false,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          textStyle: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: context.getResponsiveSize(3.5).clamp(14.0, 28.0),
                          ),
                        ),
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

                      SizedBox(height: context.heightPercent(1)),

                      // ── Password Label ──
                      Text(
                        'Password',
                        style: TextStyle(
                          fontSize: context.getResponsiveSize(3.2),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),

                      SizedBox(height: context.heightPercent(0.8)),

                      // ── Password Input ──
                      AnimatedTextField(
                        controller: passwordController,
                        hintText: 'Enter Password',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey.shade500,
                            size: context.getResponsiveSize(5),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Password is required";
                          }
                          if (value.length < 4) {
                            return "Password too short";
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: context.heightPercent(1.5)),

                      // ── Verify & Change Handset Button ──
                      SizedBox(
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
                          onPressed: (!isFormValid || _isLoading)
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) {
                                    ToastUtils.showError("Please fix the errors");
                                    return;
                                  }

                                  setState(() {
                                    _isLoading = true;
                                  });

                                  final newDeviceID = await getDeviceId();
                                  final newDeviceName = await getDeviceName();
                                  final fullPhoneNumber =
                                      '$selectedCountryCode${phoneController.text.trim()}';

                                  try {
                                    final response = await httpClient.post(
                                      ApiUrlConstants.DEVICE_CHANGE_REQUEST,
                                      options: Options(extra: {'requiresAuth': false}),
                                      data: {
                                        'phoneNumber': fullPhoneNumber,
                                        'password': passwordController.text.trim(),
                                        'newDeviceId': newDeviceID,
                                        'newDeviceName': newDeviceName,
                                      },
                                    );

                                    if (response.statusCode == 200 || response.statusCode == 201) {
                                      ToastUtils.showSuccess(
                                        response.data['message'] ??
                                            "Handset change request submitted. Please wait for admin approval.",
                                      );
                                      await Future.delayed(const Duration(seconds: 2));
                                      if (mounted) Get.back();
                                    } else {
                                      ToastUtils.showError(
                                        
                                        response.data['message'] ?? "Request failed",
                                      );
                                    }
                                  } on DioException catch (e) {
                                    String msg = "Something went wrong";
                                    if (e.response?.data != null) {
                                      msg = e.response!.data['error']?['message'] ??
                                          e.response!.data['message'] ??
                                          msg;
                                    }
                                    ToastUtils.showError(msg);
                                  } catch (e) {
                                    ToastUtils.showError(e.toString());
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    }
                                  }
                                },
                          child: _isLoading
                              ? SizedBox(
                                  height: context.getResponsiveSize(5),
                                  width: context.getResponsiveSize(5),
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Verify & Change Handset',
                                  style: TextStyle(
                                    fontSize: context.getResponsiveSize(4.2),
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
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
        ),
      );
  }
}
