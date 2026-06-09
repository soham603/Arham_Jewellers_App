import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/services/deviceIdService.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_text_field.dart';
import '../../../core/widgets/logo_widget.dart';
import '../../../presentation/controllers/AuthController.dart';
import '../../../utils/ToastUtil.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
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
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.getScreenWidth(5),
                        vertical: context.getScreenHeight(1),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 400),
                          child: Column(
                        children: [
                          // 1. Logo (Smaller as requested)
                          Center(
                            child: LogoWidget(
                              logoSize: context.getScreenWidth(16),
                              nameFontSize: context.getScreenWidth(4),
                              subtitleFontSize: context.getScreenWidth(2),
                              iconColor: context.colorPalette.gold,
                              nameColor: context.colorPalette.goldDeep,
                              subtitleColor: context.colorPalette.goldDark,
                              nameLetterSpacing: 2.0,
                              iconNameSpacing: context.getScreenHeight(0.8),
                              nameSubtitleSpacing: context.getScreenHeight(0.2),
                            ),
                          ),

                          // 2. Form Section
                          Form(
                            key: _formKey,
                            child: _buildCenterForm(context),
                          ),

                          SizedBox(height: context.getScreenHeight(2)),

                          // 3. Button (Anchored at the bottom)
                          _buildBottomButton(context),

                          SizedBox(height: context.getScreenHeight(2)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCenterForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Change Handset',
          style: TextStyle(
            fontSize: context.getResponsiveSize(5.5),
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),

        SizedBox(height: context.getScreenHeight(0.5)),

        Text(
          'Verify your identity to link this new device to your account securely.',
          style: TextStyle(
            fontSize: context.getResponsiveSize(3.3),
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),

        SizedBox(height: context.getScreenHeight(3)),

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

        AnimatedTextField(
          controller: passwordController,
          hintText: 'Enter Password',
          obscureText: _obscurePassword,
          paddingBottom: context.getScreenHeight(0.5),
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
      ],
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: context.getScreenHeight(6),
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
              borderRadius: BorderRadius.circular(context.getScreenWidth(2.5)),
            ),
          ),
        ),
        onPressed: (!isFormValid || _isLoading)
            ? null
            : () async {
                if (!_formKey.currentState!.validate()) {
                  ToastUtils.showError(context, "Please fix the errors");
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
                    '/api/v1/auth/device-change-request',
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
                      context,
                      response.data['message'] ??
                          "Handset change request submitted. Please wait for admin approval.",
                    );
                    Get.back();
                  } else {
                    ToastUtils.showError(
                      context,
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
                  ToastUtils.showError(context, msg);
                } catch (e) {
                  ToastUtils.showError(context, e.toString());
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
                height: context.getScreenWidth(5),
                width: context.getScreenWidth(5),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
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
    );
  }
}
