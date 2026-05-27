import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/services/deviceIdService.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/logo_widget.dart';
import '../../../presentation/controllers/AuthController.dart';
import '../../../utils/Enums.dart';
import '../../../utils/ToastUtil.dart';

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
    final body = GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // 🔥 dismiss keyboard
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: IntrinsicHeight(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.getScreenWidth(5),
                context.getScreenHeight(2),
                context.getScreenWidth(5),
                MediaQuery.of(context).viewInsets.bottom +
                    16, // 🔥 keyboard safe
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: context.getScreenHeight(3)),

                    Center(child: LogoWidget(size: context.getScreenWidth(35))),

                    SizedBox(height: context.getScreenHeight(5)),

                    Text(
                      'Welcome',
                      style: TextStyle(
                        fontSize: context.getScreenWidth(7),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),

                    SizedBox(height: context.getScreenHeight(0.5)),

                    Text(
                      'Sign in to continue',
                      style: TextStyle(
                        fontSize: context.getScreenWidth(4),
                        color: AppColors.textMuted,
                      ),
                    ),

                    SizedBox(height: context.getScreenHeight(2)),
                    const Divider(),
                    SizedBox(height: context.getScreenHeight(2)),

                    /// PHONE
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '+91 Enter Mobile Number',
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

                    SizedBox(height: context.getScreenHeight(2)),

                    /// PASSWORD
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Enter Password',
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

                    SizedBox(height: context.getScreenHeight(3)),

                    /// BUTTON
                    Obx(() {
                      final isLoading =
                          authController.userLoginState ==
                          CurrentAppState.LOADING;

                      return SizedBox(
                        width: double.infinity,
                        height: context.getScreenHeight(7),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFormValid
                                ? AppColors.primaryGold
                                : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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

                                  print(deviceID);

                                  // NAMAN
                                  await authController.loginAdminWithPhone(
                                    phoneNumber: phoneController.text.trim(),
                                    password: passwordController.text.trim(),
                                    deviceId: deviceID,
                                    context: context,
                                    onSuccess: () {
                                      Get.offNamed(AppRoutes.home);
                                    },
                                  );
                                },
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: context.getScreenWidth(4.5),
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      );
                    }),

                    SizedBox(height: context.getScreenHeight(2)),

                    /// OR
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.getScreenWidth(4),
                          ),
                          child: Text(
                            'or',
                            style: TextStyle(
                              fontSize: context.getScreenWidth(4),
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    SizedBox(height: context.getScreenHeight(2)),

                    /// GUEST BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: context.getScreenHeight(7),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5DFD8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => Get.offNamed(AppRoutes.home),
                        child: Text(
                          'Continue as Guest',
                          style: TextStyle(
                            fontSize: context.getScreenWidth(4.5),
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const Spacer(), // ✅ NOW SAFE

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            fontSize: context.getScreenWidth(4),
                            color: AppColors.textMuted,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Get.toNamed(AppRoutes.register),
                          child: Text(
                            'Register',
                            style: TextStyle(
                              fontSize: context.getScreenWidth(4),
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: context.getScreenHeight(3)),

                    Center(
                      child: Text(
                        'By continuing you agree to our Terms & Privacy Policy',
                        style: TextStyle(
                          fontSize: context.getScreenWidth(3.2),
                          color: const Color(0xFFA8A099),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Scaffold(body: Platform.isAndroid ? SafeArea(child: body) : body);
  }
}
