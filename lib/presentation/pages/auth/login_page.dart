import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/presentation/pages/ancillary/ancillary_page_screen.dart';
import 'package:ratnesh_gold_app/services/deviceIdService.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_text_field.dart';
import '../../../core/widgets/country_code_prefix.dart';
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
  DateTime? _lastBackPress;

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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress != null && now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          if (!kIsWeb) SystemNavigator.pop();
        } else {
          _lastBackPress = now;
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(bottom: 80, left: 16, right: 16),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
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
                        horizontal: context.getResponsiveSize(5),
                        vertical: context.heightPercent(2),
                      ),
                      child: Column(
                        children: [
                          _buildTopSection(context, hasKeyboard: hasKeyboard),

                          SizedBox(height: context.heightPercent(2)),

                          Expanded(
                            child: Center(
                              child: Form(
                                key: _formKey,
                                child: _buildFormSection(context),
                              ),
                            ),
                          ),

                          SizedBox(height: context.heightPercent(2)),

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
              ? context.heightPercent(1.5)
              : context.heightPercent(5),
        ),
        Center(
          child: LogoWidget(
            logoSize: hasKeyboard
                ? context.getResponsiveSize(14)
                : context.getResponsiveSize(24),
            nameFontSize: hasKeyboard
                ? context.getResponsiveSize(3.5)
                : context.getResponsiveSize(5.5),
            subtitleFontSize: hasKeyboard
                ? context.getResponsiveSize(2.1)
                : context.getResponsiveSize(2.8),
            iconColor: context.colorPalette.gold,
            nameColor: context.colorPalette.goldDeep,
            subtitleColor: context.colorPalette.goldDark,
            nameLetterSpacing: 2.5,
            iconNameSpacing: hasKeyboard
                ? context.heightPercent(0.4)
                : context.heightPercent(1.5),
            nameSubtitleSpacing: hasKeyboard
                ? context.heightPercent(0.15)
                : context.heightPercent(0.4),
          ),
        ),
        SizedBox(
          height: hasKeyboard
              ? context.heightPercent(0.5)
              : context.heightPercent(2),
        ),
      ],
    );
  }

  Widget _buildFormSection(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 400),
        child: SizedBox(
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
                fontSize: context.getResponsiveSize(5.5),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),

          SizedBox(height: context.heightPercent(0.3)),

          Text(
            isAdminLogin
                ? 'Sign in with admin credentials'
                : 'Sign in to access your gold account',
            style: TextStyle(
              fontSize: context.getResponsiveSize(3.3),
              color: AppColors.textMuted,
            ),
          ),

          SizedBox(height: context.heightPercent(2)),

          AnimatedTextField(
            controller: phoneController,
            hintText: 'Mobile Number',
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

          AnimatedTextField(
            controller: passwordController,
            hintText: 'Enter Password',
            obscureText: _obscurePassword,
            paddingBottom: context.heightPercent(0.5),
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
              return null;
            },
          ),

          Obx(() {
            final errorMsg = isAdminLogin
                ? authController.adminLoginErrorMsg
                : authController.userLoginErrorMsg;
            if (errorMsg.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(bottom: context.heightPercent(0.5)),
              child: Text(
                errorMsg,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.getResponsiveSize(3),
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }),

          SizedBox(height: context.heightPercent(0.5)),

          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.forgotPassword),
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: context.getResponsiveSize(3.2),
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          SizedBox(height: context.heightPercent(2)),

          Obx(() {
            final isLoading = isAdminLogin
                ? authController.adminLoginState == CurrentAppState.LOADING
                : authController.userLoginState == CurrentAppState.LOADING;

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
                onPressed: (!isFormValid || isLoading)
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) {
                          ToastUtils.showError(
                            
                            "Please fix the errors",
                          );
                          return;
                        }

                        final deviceID = await getDeviceId();
                        final fullPhoneNumber =
                            '+91${phoneController.text.trim()}';

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
                        height: context.getResponsiveSize(5),
                        width: context.getResponsiveSize(5),
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
                            fontSize: context.getResponsiveSize(4.5),
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
              ),
            );
          }),

          SizedBox(height: context.heightPercent(1.5)),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "New user? ",
                style: TextStyle(
                  fontSize: context.getResponsiveSize(3.5),
                  color: AppColors.textMuted,
                ),
              ),
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.register),
                child: Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3.5),
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: context.heightPercent(1.5)),

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
                  fontSize: context.getResponsiveSize(3.2),
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
        ),
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
                horizontal: context.getResponsiveSize(3),
                vertical: context.heightPercent(0.5),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  isAdminLogin ? 'Sign in as User' : 'Admin Login',
                  key: ValueKey<bool>(isAdminLogin),
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3),
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
        SizedBox(height: context.heightPercent(1)),
        Center(
          child: Text.rich(
            TextSpan(
              text: 'By continuing you agree to our ',
              style: TextStyle(
                fontSize: context.getResponsiveSize(2.8),
                color: AppColors.textMuted,
              ),
              children: [
                TextSpan(
                  text: 'Terms',
                  style: TextStyle(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => Get.to(() => const AncillaryPageScreen(), arguments: 'TERMS'),
                ),
                const TextSpan(text: ' & '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => Get.to(() => const AncillaryPageScreen(), arguments: 'PRIVACY'),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: context.heightPercent(1)),
      ],
    );
  }
}
