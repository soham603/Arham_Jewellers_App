import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/app/routes/app_routes.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/presentation/controllers/AuthController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  final _currentFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  late final AuthController _authController = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController());

  bool get _isAdmin => _authController.isAdmin;

  bool get _isFormValid {
    final current = _currentPasswordController.text;
    final next = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;
    return current.isNotEmpty &&
        next.length >= 6 &&
        next != current &&
        confirm == next;
  }

  String? get _newPasswordError {
    final next = _newPasswordController.text;
    if (next.isEmpty) return null;
    if (next.length < 6) return "Use at least 6 characters";
    if (next == _currentPasswordController.text) {
      return "New password must be different from the current one";
    }
    return null;
  }

  String? get _confirmPasswordError {
    final confirm = _confirmPasswordController.text;
    if (confirm.isEmpty) return null;
    if (confirm != _newPasswordController.text) return "Passwords do not match";
    return null;
  }

  @override
  void initState() {
    super.initState();
    _currentPasswordController.addListener(_refresh);
    _newPasswordController.addListener(_refresh);
    _confirmPasswordController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_isFormValid) return;

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    final success = await _authController.changePassword(
      oldPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
            size: context.getResponsiveSize(5),
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Change Password",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: context.getResponsiveSize(4.5),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.getResponsiveSize(4)),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.getResponsiveSize(4)),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.primaryGold,
                        size: context.getResponsiveSize(5),
                      ),
                    ),
                    SizedBox(width: context.getResponsiveSize(3)),
                    Expanded(
                      child: Text(
                        "Enter your current password to set a new one. You'll stay signed in.",
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: context.getResponsiveSize(3.4),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.heightPercent(2.5)),
                _passwordField(
                  context,
                  controller: _currentPasswordController,
                  focusNode: _currentFocus,
                  label: "Current password",
                  obscure: _obscureCurrent,
                  autofillHint: AutofillHints.password,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _newFocus.requestFocus(),
                  onToggle: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
                SizedBox(height: context.heightPercent(1.5)),
                _passwordField(
                  context,
                  controller: _newPasswordController,
                  focusNode: _newFocus,
                  label: "New password",
                  obscure: _obscureNew,
                  hint: "Minimum 6 characters",
                  autofillHint: AutofillHints.newPassword,
                  textInputAction: TextInputAction.next,
                  errorText: _newPasswordError,
                  onSubmitted: (_) => _confirmFocus.requestFocus(),
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                ),
                SizedBox(height: context.heightPercent(1.5)),
                _passwordField(
                  context,
                  controller: _confirmPasswordController,
                  focusNode: _confirmFocus,
                  label: "Confirm new password",
                  obscure: _obscureConfirm,
                  autofillHint: AutofillHints.newPassword,
                  textInputAction: TextInputAction.done,
                  errorText: _confirmPasswordError,
                  onSubmitted: (_) => _submit(),
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                SizedBox(height: context.heightPercent(3)),
                SizedBox(
                  width: double.infinity,
                  height: context.getResponsiveSize(12),
                  child: ElevatedButton(
                    onPressed: (_submitting || !_isFormValid) ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      disabledBackgroundColor:
                          AppColors.primaryGold.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            "Update password",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: context.getResponsiveSize(3.8),
                            ),
                          ),
                  ),
                ),
                if (!_isAdmin) ...[
                  SizedBox(height: context.heightPercent(2)),
                  Center(
                    child: GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.forgotPassword),
                      child: Text(
                        "Forgot your current password? Contact us",
                        style: TextStyle(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.w600,
                          fontSize: context.getResponsiveSize(3.3),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField(
    BuildContext context, {
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? hint,
    String? errorText,
    String? autofillHint,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: autofillHint == null ? null : [autofillHint],
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: AppColors.textMuted,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
