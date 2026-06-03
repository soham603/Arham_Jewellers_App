import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:ratnesh_gold_app/services/deviceIdService.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_text_field.dart';
import '../../../core/widgets/logo_widget.dart';
import '../../../presentation/controllers/AuthController.dart';
import '../../../utils/Enums.dart';
import '../../../utils/ToastUtil.dart';

import 'change_handset_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthController authController = Get.put(AuthController());
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isFormValid = false;
  bool isAdminLogin = false;
  bool _obscurePassword = true;
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
    final hasKeyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.getScreenWidth(5),
                        vertical: context.getScreenHeight(2),
                      ),
                      child: Column(
                        children: [
                          // 1. Logo & Header
                          _buildTopSection(context, hasKeyboard: hasKeyboard),

                          SizedBox(height: context.getScreenHeight(2)),

                          // 2. Form
                          Expanded(
                            child: Center(
                              child: Form(
                                key: _formKey,
                                child: _buildFormSection(context),
                              ),
                            ),
                          ),

                          SizedBox(height: context.getScreenHeight(2)),

                          // 3. Bottom Links & Terms
                          _buildBottomSection(context),
                        ],
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

  Widget _buildTopSection(BuildContext context, {bool hasKeyboard = false}) {
    return Column(
      children: [
        SizedBox(
          height: hasKeyboard
              ? context.getScreenHeight(1.5)
              : context.getScreenHeight(5),
        ),
        Center(
          child: LogoWidget(
            logoSize: hasKeyboard
                ? context.getScreenWidth(14)
                : context.getScreenWidth(24),
            nameFontSize: hasKeyboard
                ? context.getScreenWidth(3.5)
                : context.getScreenWidth(5.5),
            subtitleFontSize: hasKeyboard
                ? context.getScreenWidth(2.1)
                : context.getScreenWidth(2.8),
            iconColor: context.colorPalette.gold,
            nameColor: context.colorPalette.goldDeep,
            subtitleColor: context.colorPalette.goldDark,
            nameLetterSpacing: 2.5,
            iconNameSpacing: hasKeyboard
                ? context.getScreenHeight(0.4)
                : context.getScreenHeight(1.5),
            nameSubtitleSpacing: hasKeyboard
                ? context.getScreenHeight(0.15)
                : context.getScreenHeight(0.4),
          ),
        ),
        SizedBox(
          height: hasKeyboard
              ? context.getScreenHeight(0.5)
              : context.getScreenHeight(2),
        ),
      ],
    );
  }

  Widget _buildFormSection(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              isAdminLogin ? 'Admin Portal' : 'Welcome Back',
              key: ValueKey<bool>(isAdminLogin),
              style: TextStyle(
                fontSize: context.getScreenWidth(5.5),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),

          SizedBox(height: context.getScreenHeight(0.3)),

          Text(
            isAdminLogin
                ? 'Sign in with admin credentials'
                : 'Sign in to access your gold account',
            style: TextStyle(
              fontSize: context.getScreenWidth(3.3),
              color: AppColors.textMuted,
            ),
          ),

          SizedBox(height: context.getScreenHeight(2)),

          AnimatedTextField(
            controller: phoneController,
            hintText: 'Mobile Number',
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
                fontSize: context.getScreenWidth(3.5),
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
                size: context.getScreenWidth(5),
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

          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {},
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: context.getScreenWidth(3.2),
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          SizedBox(height: context.getScreenHeight(2)),

          Obx(() {
            final isLoading = isAdminLogin
                ? authController.adminLoginState == CurrentAppState.LOADING
                : authController.userLoginState == CurrentAppState.LOADING;

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
                      borderRadius: BorderRadius.circular(
                        context.getScreenWidth(2.5),
                      ),
                    ),
                  ),
                ),
                onPressed: (!isFormValid || isLoading)
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) {
                          ToastUtils.showError(
                            context,
                            "Please fix the errors",
                          );
                          return;
                        }

                        final deviceID = await getDeviceId();
                        final fullPhoneNumber =
                            '$selectedCountryCode${phoneController.text.trim()}';

                        if (isAdminLogin) {
                          await authController.loginAdminWithPhone(
                            phoneNumber: fullPhoneNumber,
                            password: passwordController.text.trim(),
                            deviceId: deviceID,
                            context: context,
                            onSuccess: () {
                              Get.offNamed(AppRoutes.home);
                            },
                          );
                        } else {
                          await authController.loginUserWithPhone(
                            phoneNumber: fullPhoneNumber,
                            password: passwordController.text.trim(),
                            deviceId: deviceID,
                            context: context,
                            onSuccess: () {
                              Get.offNamed(AppRoutes.home);
                            },
                          );
                        }
                      },
                child: isLoading
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
                          isAdminLogin ? 'Sign In as Admin' : 'Sign In',
                          key: ValueKey<bool>(isAdminLogin),
                          style: TextStyle(
                            fontSize: context.getScreenWidth(4.5),
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
              ),
            );
          }),

          SizedBox(height: context.getScreenHeight(1.5)),

          // ── Create Account Section ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "New user? ",
                style: TextStyle(
                  fontSize: context.getScreenWidth(3.5),
                  color: AppColors.textMuted,
                ),
              ),
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.register),
                child: Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: context.getScreenWidth(3.5),
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: context.getScreenHeight(1.5)),

          // 🔥 Removed underline and added space before the question mark
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangeHandsetPage(),
                  ),
                );
              },
              child: Text(
                'Change Handset ?',
                style: TextStyle(
                  fontSize: context.getScreenWidth(3.2),
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                isAdminLogin = !isAdminLogin;
              });
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.getScreenWidth(3),
                vertical: context.getScreenHeight(0.5),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  isAdminLogin ? 'Sign in as User' : 'Admin Login',
                  key: ValueKey<bool>(isAdminLogin),
                  style: TextStyle(
                    fontSize: context.getScreenWidth(3),
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: context.getScreenHeight(1)),
        Center(
          child: Text.rich(
            TextSpan(
              text: 'By continuing you agree to our ',
              style: TextStyle(
                fontSize: context.getScreenWidth(2.8),
                color: AppColors.textMuted,
              ),
              children: [
                TextSpan(
                  text: 'Terms',
                  style: TextStyle(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' & '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: context.getScreenHeight(1)),
      ],
    );
  }
}
