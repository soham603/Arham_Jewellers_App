import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/logo_widget.dart';
import '../../../utils/ToastUtil.dart';

// NAMAN - fields as per docs

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController gstController = TextEditingController();
  
  bool isFormValid = false;

  void validateForm() {
    setState(() {
      isFormValid = phoneController.text.trim().isNotEmpty &&
          usernameController.text.trim().isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    phoneController.addListener(validateForm);
    usernameController.addListener(validateForm);
  }

  @override
  void dispose() {
    phoneController.dispose();
    whatsappController.dispose();
    emailController.dispose();
    usernameController.dispose();
    addressController.dispose();
    pincodeController.dispose();
    gstController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.getScreenHeight(1.5)),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.getScreenWidth(4),
            vertical: context.getScreenHeight(1.8),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE7DED2), width: 1),
          ),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          Container(height: 4, color: AppColors.primaryGold),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.getScreenWidth(5),
                  context.getScreenHeight(2),
                  context.getScreenWidth(5),
                  MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: LogoWidget(size: context.getScreenWidth(28))),
                      SizedBox(height: context.getScreenHeight(3)),
                      
                      Text(
                        'Register',
                        style: TextStyle(
                          fontSize: context.getScreenWidth(7),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: context.getScreenHeight(0.5)),
                      Text(
                        'Create an account to continue',
                        style: TextStyle(
                          fontSize: context.getScreenWidth(4),
                          color: AppColors.textMuted,
                        ),
                      ),
                      
                      SizedBox(height: context.getScreenHeight(3)),

                      _buildTextField(
                        controller: usernameController,
                        hintText: 'Username',
                        validator: (value) => value == null || value.trim().isEmpty ? 'Username is required' : null,
                      ),
                      _buildTextField(
                        controller: phoneController,
                        hintText: '+91 Enter Mobile Number',
                        keyboardType: TextInputType.phone,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Mobile number is required' : null,
                      ),
                      _buildTextField(
                        controller: whatsappController,
                        hintText: 'Whatsapp number',
                        keyboardType: TextInputType.phone,
                      ),
                      _buildTextField(
                        controller: emailController,
                        hintText: 'Email address',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _buildTextField(
                        controller: addressController,
                        hintText: 'Address',
                      ),
                      _buildTextField(
                        controller: pincodeController,
                        hintText: 'State - Pincode',
                      ),
                      _buildTextField(
                        controller: gstController,
                        hintText: 'GST NO.',
                      ),
                      
                      SizedBox(height: context.getScreenHeight(2)),

                      SizedBox(
                        width: double.infinity,
                        height: context.getScreenHeight(7),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFormValid ? AppColors.primaryGold : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: !isFormValid ? null : () {
                            if (!_formKey.currentState!.validate()) {
                              ToastUtils.showError(context, "Please fix the errors");
                              return;
                            }
                            // Simulate registration success and navigate back to login
                            Get.offNamed(AppRoutes.login);
                          },
                          child: Text(
                            'Register',
                            style: TextStyle(
                              fontSize: context.getScreenWidth(4.5),
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: context.getScreenHeight(2)),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              fontSize: context.getScreenWidth(4),
                              color: AppColors.textMuted,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Get.offNamed(AppRoutes.login),
                            child: Text(
                              'Sign In',
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
        ],
      ),
    );
    
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Platform.isAndroid ? SafeArea(child: body) : body,
    );
  }
}
