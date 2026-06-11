import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import '../../core/theme/app_colors.dart';

class AnimatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isRequired;
  final TextInputType keyboardType;
  final bool obscureText;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final double? paddingBottom;
  final FocusNode? focusNode; // 🔥 Added this to support Autocomplete!

  const AnimatedTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.isRequired = false,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.paddingBottom,
    this.focusNode, // 🔥 Added here
  });

  @override
  State<AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<AnimatedTextField> {
  late FocusNode _focusNode;
  bool _isLocalFocusNode = false;

  @override
  void initState() {
    super.initState();
    // Use the provided focusNode if it exists, otherwise create a local one
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _isLocalFocusNode = true;
    }
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    // Only dispose the focusNode if we created it locally
    if (_isLocalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 Added a safety check: only append '*' if it doesn't already have one!
    final displayHintText =
        widget.isRequired && !widget.hintText.trim().endsWith('*')
        ? '${widget.hintText} *'
        : widget.hintText;

    return Padding(
      padding: EdgeInsets.only(
        bottom: widget.paddingBottom ?? context.getScreenHeight(1.5),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.getResponsiveSize(2.5)),
          boxShadow: _focusNode.hasFocus
              ? [
                  BoxShadow(
                    color: AppColors.primaryGold.withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: TextFormField(
          focusNode: _focusNode, // 🔥 Now perfectly wired up!
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          maxLength: widget.maxLength,
          textCapitalization: widget.textCapitalization,
          style: TextStyle(
            fontSize: context.getResponsiveSize(3.5).clamp(14.0, 28.0),
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: displayHintText,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: context.getResponsiveSize(3.5).clamp(14.0, 28.0),
            ),
            counterText: "",
            filled: true,
            fillColor: AppColors.inputFill,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
            contentPadding: EdgeInsets.symmetric(
              horizontal: context.getResponsiveSize(3.5).clamp(14.0, 20.0),
              vertical: context.getScreenHeight(1.5).clamp(10.0, 16.0),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.getResponsiveSize(2.5).clamp(8.0, 14.0)),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.getResponsiveSize(2.5).clamp(8.0, 14.0)),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.getResponsiveSize(2.5).clamp(8.0, 14.0)),
              borderSide: const BorderSide(color: AppColors.primaryGold, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.getResponsiveSize(2.5).clamp(8.0, 14.0)),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.getResponsiveSize(2.5).clamp(8.0, 14.0)),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
          validator: widget.validator,
        ),
      ),
    );
  }
}
