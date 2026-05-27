import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:country_code_picker/country_code_picker.dart'; 
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
  bool isAdminLogin = false; // Toggle state for Admin/User
  String selectedCountryCode = "+91"; // State for country code

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

  InputDecoration _buildInputDecoration(BuildContext context, {required String hintText, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: context.getScreenWidth(3.5), 
      ),
      prefixIcon: prefixIcon, 
      counterText: "", 
      filled: true,
      fillColor: const Color(0xFFF9F9F9),
      contentPadding: EdgeInsets.symmetric(
        horizontal: context.getScreenWidth(3.5), 
        vertical: context.getScreenHeight(1.5), 
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(context.getScreenWidth(2.5)), 
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(context.getScreenWidth(2.5)), 
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(context.getScreenWidth(2.5)), 
        borderSide: BorderSide(color: AppColors.primaryGold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(context.getScreenWidth(2.5)), 
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 We calculate the safe height so elements don't get pushed off screen
    final safeHeight = MediaQuery.of(context).size.height - 
                       MediaQuery.of(context).padding.top - 
                       MediaQuery.of(context).padding.bottom;

    final body = GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: safeHeight, // 🔥 Updated to use safe height
          ),
          child: IntrinsicHeight(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.getScreenWidth(5),
                context.getScreenHeight(1.5), 
                context.getScreenWidth(5),
                MediaQuery.of(context).viewInsets.bottom + context.getScreenHeight(2), 
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: context.getScreenHeight(2)),

                    Center(child: LogoWidget(size: context.getScreenWidth(28))), 

                    SizedBox(height: context.getScreenHeight(3.5)),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        isAdminLogin ? 'Admin Portal' : 'Welcome', 
                        key: ValueKey<bool>(isAdminLogin),
                        style: TextStyle(
                          fontSize: context.getScreenWidth(6), 
                          fontWeight: FontWeight.w700, 
                          color: AppColors.textDark,
                        ),
                      ),
                    ),

                    SizedBox(height: context.getScreenHeight(0.5)),

                    Text(
                      'Sign in to continue',
                      style: TextStyle(
                        fontSize: context.getScreenWidth(3.5),
                        color: AppColors.textMuted,
                      ),
                    ),

                    SizedBox(height: context.getScreenHeight(2.5)), 

                    /// PHONE
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10, 
                      style: TextStyle(
                        fontSize: context.getScreenWidth(3.5), 
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _buildInputDecoration(
                        context, 
                        hintText: 'Enter Mobile Number',
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
                          alignLeft: false,
                          padding: const EdgeInsets.all(0),
                          textStyle: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: context.getScreenWidth(3.5),
                          ),
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

                    SizedBox(height: context.getScreenHeight(1.5)),

                    /// PASSWORD
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      style: TextStyle(
                        fontSize: context.getScreenWidth(3.5), 
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _buildInputDecoration(
                        context, 
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

                    /// MAIN SIGN IN BUTTON
                    Obx(() {
                      final isLoading = isAdminLogin
                          ? authController.adminLoginState == CurrentAppState.LOADING
                          : authController.userLoginState == CurrentAppState.LOADING;

                      return SizedBox(
                        width: double.infinity,
                        height: context.getScreenHeight(6), 
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFormValid
                                ? AppColors.primaryGold
                                : Colors.grey.shade400,
                            elevation: isFormValid ? 2 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(context.getScreenWidth(2.5)), 
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
                                  final fullPhoneNumber = '$selectedCountryCode${phoneController.text.trim()}';

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
                                      fontSize: context.getScreenWidth(4),
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                        ),
                      );
                    }),

                    SizedBox(height: context.getScreenHeight(2.5)),

                    /// OR Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.getScreenWidth(4),
                          ),
                          child: Text(
                            'or',
                            style: TextStyle(
                              fontSize: context.getScreenWidth(3.5),
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),

                    SizedBox(height: context.getScreenHeight(2.5)),

                    /// GUEST BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: context.getScreenHeight(6), 
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF2EFEA), 
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(context.getScreenWidth(2.5)), 
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => Get.offNamed(AppRoutes.home),
                        child: Text(
                          'Continue as Guest',
                          style: TextStyle(
                            fontSize: context.getScreenWidth(4),
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // 🔥 Replaced Spacer() with a fixed SizedBox to prevent overflowing
                    SizedBox(height: context.getScreenHeight(4)),
                    Spacer(),

                    /// ADMIN / USER TOGGLE
                    Center(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(context.getScreenWidth(2)), 
                        onTap: () {
                          setState(() {
                            isAdminLogin = !isAdminLogin; 
                          });
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.getScreenWidth(3), 
                            vertical: context.getScreenHeight(1), 
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isAdminLogin 
                                  ? Icons.person_outline 
                                  : Icons.admin_panel_settings_outlined,
                                size: context.getScreenWidth(4.5),
                                color: AppColors.textDark,
                              ),
                              SizedBox(width: context.getScreenWidth(2)), 
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  isAdminLogin ? 'Sign in as User' : 'Sign in as Admin',
                                  key: ValueKey<bool>(isAdminLogin),
                                  style: TextStyle(
                                    fontSize: context.getScreenWidth(3.8),
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: context.getScreenHeight(2)),

                    /// REGISTER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            fontSize: context.getScreenWidth(3.5), 
                            color: AppColors.textMuted,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Get.toNamed(AppRoutes.register),
                          child: Text(
                            'Register',
                            style: TextStyle(
                              fontSize: context.getScreenWidth(3.5), 
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
                          fontSize: context.getScreenWidth(3), 
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: body), 
    );
  }
}