import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:country_code_picker/country_code_picker.dart';
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

  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController gstController;
  late final TextEditingController stateController;
  late final TextEditingController cityController;
  late final TextEditingController areaController;
  late final TextEditingController pincodeController;
  late final TextEditingController companyNameController;

  String? _selectedState;
  String? _selectedCity;
  String _selectedCountryCode = '+91';
  bool _isFormValid = false;
  bool _isSubmitting = false;

  // ───────────────────────── India States & Cities ─────────────────────────
  static const Map<String, List<String>> _indiaData = {
    'Andhra Pradesh': [
      'Visakhapatnam', 'Vijayawada', 'Guntur', 'Nellore', 'Tirupati',
    ],
    'Arunachal Pradesh': ['Itanagar', 'Naharlagun', 'Pasighat', 'Tawang'],
    'Assam': ['Guwahati', 'Silchar', 'Dibrugarh', 'Jorhat', 'Nagaon'],
    'Bihar': ['Patna', 'Gaya', 'Muzaffarpur', 'Bhagalpur', 'Darbhanga'],
    'Chhattisgarh': ['Raipur', 'Bhilai', 'Bilaspur', 'Korba', 'Durg'],
    'Delhi': ['New Delhi', 'North Delhi', 'South Delhi', 'Dwarka'],
    'Goa': ['Panaji', 'Margao', 'Vasco da Gama', 'Mapusa'],
    'Gujarat': [
      'Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar', 'Jamnagar',
    ],
    'Haryana': [
      'Gurugram', 'Faridabad', 'Panipat', 'Ambala', 'Karnal', 'Hisar',
    ],
    'Himachal Pradesh': ['Shimla', 'Manali', 'Dharamshala', 'Solan', 'Mandi'],
    'Jharkhand': ['Ranchi', 'Jamshedpur', 'Dhanbad', 'Bokaro', 'Hazaribagh'],
    'Karnataka': [
      'Bengaluru', 'Mysuru', 'Mangaluru', 'Hubballi', 'Belagavi',
    ],
    'Kerala': [
      'Thiruvananthapuram', 'Kochi', 'Kozhikode', 'Thrissur', 'Kollam',
    ],
    'Madhya Pradesh': [
      'Bhopal', 'Indore', 'Gwalior', 'Jabalpur', 'Ujjain',
    ],
    'Maharashtra': [
      'Mumbai', 'Pune', 'Nagpur', 'Thane', 'Nashik', 'Aurangabad',
    ],
    'Manipur': ['Imphal', 'Thoubal', 'Bishnupur'],
    'Meghalaya': ['Shillong', 'Tura', 'Jowai'],
    'Mizoram': ['Aizawl', 'Lunglei', 'Champhai'],
    'Nagaland': ['Kohima', 'Dimapur', 'Mokokchung'],
    'Odisha': [
      'Bhubaneswar', 'Cuttack', 'Rourkela', 'Berhampur', 'Sambalpur',
    ],
    'Punjab': [
      'Chandigarh', 'Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala',
    ],
    'Rajasthan': [
      'Jaipur', 'Jodhpur', 'Udaipur', 'Kota', 'Bikaner', 'Ajmer',
    ],
    'Sikkim': ['Gangtok', 'Namchi', 'Gyalshing'],
    'Tamil Nadu': [
      'Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem',
    ],
    'Telangana': [
      'Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar', 'Khammam',
    ],
    'Tripura': ['Agartala', 'Udaipur', 'Dharmanagar'],
    'Uttar Pradesh': [
      'Lucknow', 'Kanpur', 'Agra', 'Varanasi', 'Meerut', 'Noida',
    ],
    'Uttarakhand': [
      'Dehradun', 'Haridwar', 'Rishikesh', 'Nainital', 'Haldwani',
    ],
    'West Bengal': [
      'Kolkata', 'Howrah', 'Darjeeling', 'Siliguri', 'Asansol',
    ],
  };

  // ───────────────────────── Validators ─────────────────────────
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _gstRegex = RegExp(
    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
  );

  static final RegExp _phoneRegex = RegExp(r'^[6-9]\d{9}$');

  static final RegExp _pincodeRegex = RegExp(r'^[1-9][0-9]{5}$');

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) return 'Password is required';
    if (value.trim().length < 8) return 'Minimum 8 characters required';
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name is too short';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Mobile number is required';
    if (!_phoneRegex.hasMatch(value.trim())) return 'Enter a valid 10‑digit number';
    return null;
  }

  String? _validateGST(String? value) {
    if (value == null || value.trim().isEmpty) return 'GST number is required';
    if (!_gstRegex.hasMatch(value.trim().toUpperCase())) {
      return 'Enter a valid 15‑digit GST number';
    }
    return null;
  }

  String? _validateRequired(String field, String? value) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  String? _validatePincode(String? value) {
    if (value == null || value.trim().isEmpty) return 'Pincode is required';
    if (!_pincodeRegex.hasMatch(value.trim())) return 'Enter a valid 6‑digit pincode';
    return null;
  }

  // ───────────────────────── Form State Helpers ─────────────────────────
  void _onFieldChanged() {
    final valid = emailController.text.trim().isNotEmpty &&
        passwordController.text.trim().isNotEmpty &&
        nameController.text.trim().isNotEmpty &&
        phoneController.text.trim().isNotEmpty &&
        gstController.text.trim().isNotEmpty &&
        stateController.text.trim().isNotEmpty &&
        cityController.text.trim().isNotEmpty &&
        areaController.text.trim().isNotEmpty &&
        pincodeController.text.trim().isNotEmpty &&
        companyNameController.text.trim().isNotEmpty;

    if (valid != _isFormValid) {
      setState(() => _isFormValid = valid);
    }
  }

  List<TextEditingController> get _allControllers => [
        emailController,
        passwordController,
        nameController,
        phoneController,
        gstController,
        stateController,
        cityController,
        areaController,
        pincodeController,
        companyNameController,
      ];

  // ───────────────────────── Lifecycle ─────────────────────────
  @override
  void initState() {
    super.initState();

    emailController = TextEditingController();
    passwordController = TextEditingController();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    gstController = TextEditingController();
    stateController = TextEditingController();
    cityController = TextEditingController();
    areaController = TextEditingController();
    pincodeController = TextEditingController();
    companyNameController = TextEditingController();

    for (final c in _allControllers) {
      c.addListener(_onFieldChanged);
    }
  }

  @override
  void dispose() {
    for (final c in _allControllers) {
      c.removeListener(_onFieldChanged);
      c.dispose();
    }
    super.dispose();
  }

  // ───────────────────────── Submit ─────────────────────────
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      ToastUtils.showError(context, 'Please fix the errors');
      return;
    }

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final results = await Future.wait([
        getDeviceId(),
        getDeviceName(),
      ]);

      final deviceId = results[0];
      final deviceName = results[1];
      final fullPhoneNumber =
          '$_selectedCountryCode${phoneController.text.trim()}';
      final fcmToken = NotificationService().fcmToken;

      await authController.registerUser(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        name: nameController.text.trim(),
        phoneNumber: fullPhoneNumber,
        deviceId: deviceId,
        deviceName: deviceName,
        gstNumber: gstController.text.trim().toUpperCase(),
        state: stateController.text.trim(),
        city: cityController.text.trim(),
        area: areaController.text.trim(),
        pincode: pincodeController.text.trim(),
        companyName: companyNameController.text.trim(),
        fcmToken: fcmToken,
        context: context,
        onSuccess: () => Get.offNamed(AppRoutes.login),
      );
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ───────────────────────── Styled Dropdown Builder ─────────────────────────
  Widget _buildStyledDropdown({
    required String hintText,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.getScreenHeight(1.5)),
      child: Container(
        height: context.getScreenHeight(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.getResponsiveSize(2.5)),
          color: const Color(0xFFF9F9F9),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            padding: EdgeInsets.symmetric(
              horizontal: context.getResponsiveSize(3.5).clamp(14.0, 20.0),
            ),
            hint: Text(
              hintText,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: context.getResponsiveSize(3.5).clamp(14.0, 28.0),
              ),
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: context.getResponsiveSize(5),
              color: Colors.grey.shade500,
            ),
            style: TextStyle(
              fontSize: context.getResponsiveSize(3.5).clamp(14.0, 28.0),
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Build ─────────────────────────
  @override
  Widget build(BuildContext context) {
    final safeHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom -
        kToolbarHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textDark,
            size: context.getResponsiveSize(5),
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Container(height: 3, color: AppColors.primaryGold),
            Expanded(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: safeHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.getResponsiveSize(5),
                        context.getScreenHeight(1),
                        context.getResponsiveSize(5),
                        MediaQuery.of(context).viewInsets.bottom +
                            context.getScreenHeight(2),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: context.getScreenHeight(2)),

                                // ── Header ──
                                Text(
                                  'Register',
                                  style: TextStyle(
                                    fontSize: context.getResponsiveSize(6),
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                SizedBox(height: context.getScreenHeight(0.5)),
                                Text(
                                  'Create an account to continue',
                                  style: TextStyle(
                                    fontSize: context.getResponsiveSize(3.5),
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                SizedBox(height: context.getScreenHeight(2.5)),

                                // 1 ── EMAIL
                                AnimatedTextField(
                                  controller: emailController,
                                  hintText: 'Email Address *',
                                  keyboardType: TextInputType.emailAddress,
                                  isRequired: true,
                                  validator: _validateEmail,
                                ),

                                // 2 ── PASSWORD
                                AnimatedTextField(
                                  controller: passwordController,
                                  hintText: 'Create Password *',
                                  obscureText: true,
                                  isRequired: true,
                                  validator: _validatePassword,
                                ),

                                // 3 ── NAME
                                AnimatedTextField(
                                  controller: nameController,
                                  hintText: 'Full Name *',
                                  textCapitalization: TextCapitalization.words,
                                  isRequired: true,
                                  validator: _validateName,
                                ),

                                // 4 ── PHONE
                                AnimatedTextField(
                                  controller: phoneController,
                                  hintText: 'Enter Mobile Number *',
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  isRequired: true,
                                  prefixIcon: CountryCodePicker(
                                    onChanged: (code) {
                                      _selectedCountryCode =
                                          code.dialCode ?? '+91';
                                    },
                                    initialSelection: 'IN',
                                    favorite: const ['+91', 'IN'],
                                    showCountryOnly: false,
                                    showOnlyCountryWhenClosed: false,
                                    showDropDownButton: false,
                                    showFlag: false,
                                    alignLeft: false,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    textStyle: TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w600,
                                      fontSize: context
                                          .getResponsiveSize(3.5)
                                          .clamp(14.0, 28.0),
                                    ),
                                  ),
                                  validator: _validatePhone,
                                ),

                                // 5 ── GST NUMBER
                                AnimatedTextField(
                                  controller: gstController,
                                  hintText: 'GST NO. *',
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  maxLength: 15,
                                  isRequired: true,
                                  validator: _validateGST,
                                ),

                                // 6 ── STATE
                                _buildStyledDropdown(
                                  hintText: 'State *',
                                  value: _selectedState,
                                  items: _indiaData.keys.toList()..sort(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedState = value;
                                      _selectedCity = null;
                                      stateController.text = value ?? '';
                                      cityController.clear();
                                    });
                                  },
                                ),

                                // 7 ── CITY (dynamic based on state)
                                _buildStyledDropdown(
                                  hintText: 'City *',
                                  value: _selectedCity,
                                  items: _selectedState != null
                                      ? _indiaData[_selectedState]!
                                      : [],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCity = value;
                                      cityController.text = value ?? '';
                                    });
                                  },
                                ),

                                // 8 ── AREA
                                AnimatedTextField(
                                  controller: areaController,
                                  hintText: 'Area *',
                                  textCapitalization: TextCapitalization.words,
                                  isRequired: true,
                                  validator: (v) =>
                                      _validateRequired('Area', v),
                                ),

                                // 9 ── PINCODE
                                AnimatedTextField(
                                  controller: pincodeController,
                                  hintText: 'Pincode *',
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  isRequired: true,
                                  validator: _validatePincode,
                                ),

                                // 10 ── COMPANY NAME
                                AnimatedTextField(
                                  controller: companyNameController,
                                  hintText: 'Company Name *',
                                  textCapitalization: TextCapitalization.words,
                                  isRequired: true,
                                  validator: (v) =>
                                      _validateRequired('Company Name', v),
                                ),

                                SizedBox(height: context.getScreenHeight(1)),

                                // ── REGISTER BUTTON ──
                                Obx(() {
                                  final isLoading =
                                      authController.userRegisterState ==
                                              CurrentAppState.LOADING ||
                                          _isSubmitting;

                                  return SizedBox(
                                    width: double.infinity,
                                    height: context.getScreenHeight(6),
                                    child: ElevatedButton(
                                      style: ButtonStyle(
                                        backgroundColor:
                                            WidgetStateProperty.resolveWith(
                                          (states) => states.contains(
                                                  WidgetState.disabled)
                                              ? AppColors.primaryGold
                                                  .withValues(alpha: 0.35)
                                              : AppColors.primaryGold,
                                        ),
                                        elevation:
                                            WidgetStateProperty.resolveWith(
                                          (states) => states.contains(
                                                  WidgetState.disabled)
                                              ? 0
                                              : 2,
                                        ),
                                        shape: WidgetStateProperty.all(
                                          RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(
                                              context.getResponsiveSize(2.5),
                                            ),
                                          ),
                                        ),
                                      ),
                                      onPressed:
                                          (!_isFormValid || isLoading)
                                              ? null
                                              : _handleRegister,
                                      child: isLoading
                                          ? SizedBox(
                                              height:
                                                  context.getResponsiveSize(5),
                                              width:
                                                  context.getResponsiveSize(5),
                                              child:
                                                  const CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : Text(
                                              'Register',
                                              style: TextStyle(
                                                fontSize: context
                                                    .getResponsiveSize(4),
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

                                // ── Footer ──
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account? ',
                                      style: TextStyle(
                                        fontSize:
                                            context.getResponsiveSize(3.5),
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          Get.offNamed(AppRoutes.login),
                                      child: Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize:
                                              context.getResponsiveSize(3.5),
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
                                      fontSize: context.getResponsiveSize(3),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}