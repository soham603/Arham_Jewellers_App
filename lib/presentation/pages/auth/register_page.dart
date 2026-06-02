import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:ratnesh_gold_app/services/deviceIdService.dart';
import 'package:ratnesh_gold_app/services/notification_service.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_text_field.dart';
import '../../../presentation/controllers/AuthController.dart';
import '../../../utils/Enums.dart';
import '../../../utils/ToastUtil.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthController authController = Get.put(AuthController());
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController gstController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();

  String selectedCountryCode = "+91";
  bool isFormValid = false;

  void validateForm() {
    setState(() {
      isFormValid =
          emailController.text.trim().isNotEmpty &&
          passwordController.text.trim().isNotEmpty &&
          nameController.text.trim().isNotEmpty &&
          phoneController.text.trim().isNotEmpty &&
          gstController.text.trim().isNotEmpty &&
          pincodeController.text.trim().isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    emailController.addListener(validateForm);
    passwordController.addListener(validateForm);
    nameController.addListener(validateForm);
    phoneController.addListener(validateForm);
    gstController.addListener(validateForm);
    pincodeController.addListener(validateForm);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    gstController.dispose();
    cityController.dispose();
    areaController.dispose();
    pincodeController.dispose();
    companyNameController.dispose();
    super.dispose();
  }

  Future<String> getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.model;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.name;
      }
    } catch (e) {
      return 'Unknown Device';
    }
    return 'Unknown Device';
  }

  @override
  Widget build(BuildContext context) {
    // Calculate safe height
    final safeHeight =
        MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom -
        kToolbarHeight;

    final body = GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          Container(height: 3, color: AppColors.primaryGold),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: safeHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.getScreenWidth(5),
                      context.getScreenHeight(1),
                      context.getScreenWidth(5),
                      MediaQuery.of(context).viewInsets.bottom +
                          context.getScreenHeight(2),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: context.getScreenHeight(2)),

                          Text(
                            'Register',
                            style: TextStyle(
                              fontSize: context.getScreenWidth(6),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: context.getScreenHeight(0.5)),
                          Text(
                            'Create an account to continue',
                            style: TextStyle(
                              fontSize: context.getScreenWidth(3.5),
                              color: AppColors.textMuted,
                            ),
                          ),

                          SizedBox(height: context.getScreenHeight(2.5)),

                          // 1. EMAIL
                          AnimatedTextField(
                            controller: emailController,
                            hintText: 'Email Address',
                            keyboardType: TextInputType.emailAddress,
                            isRequired: true,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Email is required'
                                : null,
                          ),

                          // 2. PASSWORD
                          AnimatedTextField(
                            controller: passwordController,
                            hintText: 'Create Password',
                            obscureText: true,
                            isRequired: true,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Password is required'
                                : null,
                          ),

                          // 3. NAME
                          AnimatedTextField(
                            controller: nameController,
                            hintText: 'Full Name',
                            textCapitalization: TextCapitalization.words,
                            isRequired: true,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Name is required'
                                : null,
                          ),

                          // 4. PHONE NUMBER
                          AnimatedTextField(
                            controller: phoneController,
                            hintText: 'Enter Mobile Number',
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            isRequired: true,
                            prefixIcon: CountryCodePicker(
                              onChanged: (countryCode) {
                                setState(() {
                                  selectedCountryCode =
                                      countryCode.dialCode ?? "+91";
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
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Mobile number is required'
                                : null,
                          ),

                          // 5. GST NUMBER
                          AnimatedTextField(
                            controller: gstController,
                            hintText: 'GST NO.',
                            textCapitalization: TextCapitalization.characters,
                            isRequired: true,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'GST number is required'
                                : null,
                          ),

                          // 6. CITY
                          AnimatedTextField(
                            controller: cityController,
                            hintText: 'City',
                            textCapitalization: TextCapitalization.words,
                          ),

                          // 7. AREA
                          AnimatedTextField(
                            controller: areaController,
                            hintText: 'Area',
                            textCapitalization: TextCapitalization.words,
                          ),

                          // 8. PINCODE
                          AnimatedTextField(
                            controller: pincodeController,
                            hintText: 'Pincode',
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            isRequired: true,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Pincode is required'
                                : null,
                          ),

                          // 9. COMPANY NAME
                          AnimatedTextField(
                            controller: companyNameController,
                            hintText: 'Company Name',
                            textCapitalization: TextCapitalization.words,
                          ),

                          SizedBox(height: context.getScreenHeight(1)),

                          /// REGISTER BUTTON
                          Obx(() {
                            final isLoading =
                                authController.userRegisterState ==
                                CurrentAppState.LOADING;

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
                                        if (!_formKey.currentState!
                                            .validate()) {
                                          ToastUtils.showError(
                                            context,
                                            "Please fix the errors",
                                          );
                                          return;
                                        }

                                        final deviceID = await getDeviceId();
                                        final deviceName =
                                            await getDeviceName();
                                        final fullPhoneNumber =
                                            '$selectedCountryCode${phoneController.text.trim()}';

                                        final fcmToken =
                                            NotificationService().fcmToken;

                                        await authController.registerUser(
                                          email: emailController.text.trim(),
                                          password: passwordController.text
                                              .trim(),
                                          name: nameController.text.trim(),
                                          phoneNumber: fullPhoneNumber,
                                          deviceId: deviceID,
                                          deviceName: deviceName,
                                          gstNumber: gstController.text.trim(),
                                          city: cityController.text.trim(),
                                          area: areaController.text.trim(),
                                          pincode: pincodeController.text
                                              .trim(),
                                          companyName: companyNameController
                                              .text
                                              .trim(),
                                          fcmToken: fcmToken,
                                          context: context,
                                          onSuccess: () {
                                            // 🔥 This handles the direct routing to Login upon success
                                            Get.offNamed(AppRoutes.login);
                                            ToastUtils.showSuccess(
                                              context,
                                              "Registration Successful! Please login.",
                                            );
                                          },
                                        );
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
                                    : Text(
                                        'Register',
                                        style: TextStyle(
                                          fontSize: context.getScreenWidth(4),
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            );
                          }),

                          const Spacer(),
                          SizedBox(height: context.getScreenHeight(2)),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  fontSize: context.getScreenWidth(3.5),
                                  color: AppColors.textMuted,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Get.offNamed(AppRoutes.login),
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: context.getScreenWidth(3.5),
                                    color: AppColors.primaryGold,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: context.getScreenHeight(2)),

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
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textDark,
            size: context.getScreenWidth(5),
          ),
          onPressed: () => Get.back(),
        ),
      ),
      // 🔥 Removed the local SafeArea wrapper here since it is now handled globally in app.dart!
      body: body,
    );
  }
}
