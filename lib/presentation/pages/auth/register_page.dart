import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:ratnesh_gold_app/services/deviceIdService.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/logo_widget.dart';
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? prefixIcon,
    bool obscureText = false,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.getScreenHeight(1.5)),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLength: maxLength,
        textCapitalization: textCapitalization,
        style: TextStyle(
          fontSize: context.getScreenWidth(3.5),
          color: AppColors.textDark,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: context.getScreenWidth(3.5),
          ),
          counterText: "",
          filled: true,
          fillColor: const Color(0xFFF9F9F9),
          prefixIcon: prefixIcon,
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
        ),
        validator: validator,
      ),
    );
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
                          Center(
                            child: LogoWidget(size: context.getScreenWidth(28)),
                          ),
                          SizedBox(height: context.getScreenHeight(3)),

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
                          _buildTextField(
                            controller: emailController,
                            hintText: 'Email Address *',
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Email is required'
                                : null,
                          ),

                          // 2. PASSWORD
                          _buildTextField(
                            controller: passwordController,
                            hintText: 'Create Password *',
                            obscureText: true,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Password is required'
                                : null,
                          ),

                          // 3. NAME
                          _buildTextField(
                            controller: nameController,
                            hintText: 'Full Name *',
                            textCapitalization: TextCapitalization.words,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Name is required'
                                : null,
                          ),

                          // 4. PHONE NUMBER
                          _buildTextField(
                            controller: phoneController,
                            hintText: 'Enter Mobile Number *',
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
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
                              alignLeft: false,
                              padding: const EdgeInsets.all(0),
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
                          _buildTextField(
                            controller: gstController,
                            hintText: 'GST NO.',
                            textCapitalization: TextCapitalization.characters,
                          ),

                          // 6. CITY
                          _buildTextField(
                            controller: cityController,
                            hintText: 'City',
                            textCapitalization: TextCapitalization.words,
                          ),

                          // 7. AREA
                          _buildTextField(
                            controller: areaController,
                            hintText: 'Area',
                            textCapitalization: TextCapitalization.words,
                          ),

                          // 8. PINCODE
                          _buildTextField(
                            controller: pincodeController,
                            hintText: 'Pincode *',
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Pincode is required'
                                : null,
                          ),

                          // 9. COMPANY NAME
                          _buildTextField(
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFormValid
                                      ? AppColors.primaryGold
                                      : Colors.grey.shade400,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      context.getScreenWidth(2.5),
                                    ),
                                  ),
                                  elevation: isFormValid ? 2 : 0,
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
                                            "placeholder_fcm_token"; // Replace with Firebase token later

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
