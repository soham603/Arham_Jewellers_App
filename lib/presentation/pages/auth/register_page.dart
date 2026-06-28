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
  late final TextEditingController staffNameController;
  late final TextEditingController staffPhoneController;

  String? _selectedState;
  String? _selectedCity;
  String _selectedCountryCode = '+91';
  bool _isFormValid = false;
  bool _isSubmitting = false;

  //  India States & Cities 
  static const Map<String, List<String>> _indiaData = {
    'Andhra Pradesh': [
      'Visakhapatnam',
      'Vijayawada',
      'Guntur',
      'Nellore',
      'Tirupati',
    ],
    'Arunachal Pradesh': ['Itanagar', 'Naharlagun', 'Pasighat', 'Tawang'],
    'Assam': ['Guwahati', 'Silchar', 'Dibrugarh', 'Jorhat', 'Nagaon'],
    'Bihar': ['Patna', 'Gaya', 'Muzaffarpur', 'Bhagalpur', 'Darbhanga'],
    'Chhattisgarh': ['Raipur', 'Bhilai', 'Bilaspur', 'Korba', 'Durg'],
    'Delhi': ['New Delhi', 'North Delhi', 'South Delhi', 'Dwarka'],
    'Goa': ['Panaji', 'Margao', 'Vasco da Gama', 'Mapusa'],
    'Gujarat': [
      'Ahmedabad',
      'Surat',
      'Vadodara',
      'Rajkot',
      'Bhavnagar',
      'Jamnagar',
    ],
    'Haryana': [
      'Gurugram',
      'Faridabad',
      'Panipat',
      'Ambala',
      'Karnal',
      'Hisar',
    ],
    'Himachal Pradesh': ['Shimla', 'Manali', 'Dharamshala', 'Solan', 'Mandi'],
    'Jharkhand': ['Ranchi', 'Jamshedpur', 'Dhanbad', 'Bokaro', 'Hazaribagh'],
    'Karnataka': ['Bengaluru', 'Mysuru', 'Mangaluru', 'Hubballi', 'Belagavi'],
    'Kerala': [
      'Thiruvananthapuram',
      'Kochi',
      'Kozhikode',
      'Thrissur',
      'Kollam',
    ],
    'Madhya Pradesh': ['Bhopal', 'Indore', 'Gwalior', 'Jabalpur', 'Ujjain'],
    'Maharashtra': [
      'Mumbai',
      'Pune',
      'Nagpur',
      'Thane',
      'Nashik',
      'Aurangabad',
    ],
    'Manipur': ['Imphal', 'Thoubal', 'Bishnupur'],
    'Meghalaya': ['Shillong', 'Tura', 'Jowai'],
    'Mizoram': ['Aizawl', 'Lunglei', 'Champhai'],
    'Nagaland': ['Kohima', 'Dimapur', 'Mokokchung'],
    'Odisha': ['Bhubaneswar', 'Cuttack', 'Rourkela', 'Berhampur', 'Sambalpur'],
    'Punjab': ['Chandigarh', 'Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala'],
    'Rajasthan': ['Jaipur', 'Jodhpur', 'Udaipur', 'Kota', 'Bikaner', 'Ajmer'],
    'Sikkim': ['Gangtok', 'Namchi', 'Gyalshing'],
    'Tamil Nadu': [
      'Chennai',
      'Coimbatore',
      'Madurai',
      'Tiruchirappalli',
      'Salem',
    ],
    'Telangana': [
      'Hyderabad',
      'Warangal',
      'Nizamabad',
      'Karimnagar',
      'Khammam',
    ],
    'Tripura': ['Agartala', 'Udaipur', 'Dharmanagar'],
    'Uttar Pradesh': [
      'Lucknow',
      'Kanpur',
      'Agra',
      'Varanasi',
      'Meerut',
      'Noida',
    ],
    'Uttarakhand': [
      'Dehradun',
      'Haridwar',
      'Rishikesh',
      'Nainital',
      'Haldwani',
    ],
    'West Bengal': ['Kolkata', 'Howrah', 'Darjeeling', 'Siliguri', 'Asansol'],
  };

  //  Validators 
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
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name is too short';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    if (!_phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid 10‑digit number';
    }
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
    if (!_pincodeRegex.hasMatch(value.trim())) {
      return 'Enter a valid 6‑digit pincode';
    }
    return null;
  }

  //  Form State Helpers 
  void _onFieldChanged() {
    final valid =
        emailController.text.trim().isNotEmpty &&
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
    staffNameController,
    staffPhoneController,
  ];

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
    staffNameController = TextEditingController();
    staffPhoneController = TextEditingController();

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

  //  Submit (UPDATED FIX) 
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      ToastUtils.showError('Please fix the errors');
      return;
    }

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      // safely fetch as dynamic so the compiler doesn't enforce List vs String
      dynamic rawId = await getDeviceId();
      dynamic rawName = await getDeviceName();

      // Safely convert to a pure String whether it returned a String or a List<String>
      final String finalDeviceId = rawId is List
          ? rawId.join(' ')
          : rawId.toString();
      final String finalDeviceName = rawName is List
          ? rawName.join(' ')
          : rawName.toString();

      final fullPhoneNumber =
          '$_selectedCountryCode${phoneController.text.trim()}';
      final fcmToken = NotificationService().fcmToken;

      await authController.registerUser(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        name: nameController.text.trim(),
        phoneNumber: fullPhoneNumber,
        deviceId: finalDeviceId, // Guaranteed to be a valid String now
        deviceName: finalDeviceName, // Guaranteed to be a valid String now
        gstNumber: gstController.text.trim().toUpperCase(),
        state: stateController.text.trim(),
        city: cityController.text.trim(),
        area: areaController.text.trim(),
        pincode: pincodeController.text.trim(),
        companyName: companyNameController.text.trim(),
        staffName: staffNameController.text.trim(),
        staffPhoneNumber: staffPhoneController.text.trim(),
        fcmToken: fcmToken,
        context: context,
        onSuccess: () => Get.offNamed(AppRoutes.login),
      );
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  //  Modern Bottom Sheet with Search 
  void _showSearchSelectionBottomSheet({
    required String title,
    required List<String> items,
    required ValueChanged<String> onSelected,
  }) {
    final searchController = TextEditingController();
    var filteredItems = List<String>.from(items);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: context.heightPercent(70),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(4.5),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.grey,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        filteredItems = items
                            .where(
                              (item) => item.toLowerCase().contains(
                                val.toLowerCase(),
                              ),
                            )
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredItems.isEmpty
                        ? const Center(child: Text('No matches found'))
                        : ListView.builder(
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(
                                  filteredItems[index],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                ),
                                onTap: () {
                                  onSelected(filteredItems[index]);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  //  Compact Card Dropdown 
  Widget _buildCompactDropdownCard({
    required String hintText,
    required String? value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.heightPercent(1.5)),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: context.heightPercent(5.5).clamp(46.0, 60.0),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.getResponsiveSize(2.5)),
            color: const Color(0xFFF9F9F9),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value ?? hintText,
                style: TextStyle(
                  color: value == null
                      ? Colors.grey.shade400
                      : AppColors.textDark,
                  fontSize: context.getResponsiveSize(3.5).clamp(14.0, 28.0),
                  fontWeight: value == null
                      ? FontWeight.normal
                      : FontWeight.w500,
                ),
              ),
              Icon(
                Icons.unfold_more_rounded,
                size: context.getResponsiveSize(5),
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  //  Build 
  @override
  Widget build(BuildContext context) {
    final safeHeight =
        MediaQuery.of(context).size.height -
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
                        context.getResponsiveSize(4.5),
                        context.heightPercent(1),
                        context.getResponsiveSize(4.5),
                        MediaQuery.of(context).viewInsets.bottom +
                            context.heightPercent(2),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 380),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: context.heightPercent(2)),

                                // ── Header ──
                                Text(
                                  'Register',
                                  style: TextStyle(
                                    fontSize: context.getResponsiveSize(6),
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                SizedBox(height: context.heightPercent(0.5)),
                                Text(
                                  'Create an account to continue',
                                  style: TextStyle(
                                    fontSize: context.getResponsiveSize(3.5),
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                SizedBox(height: context.heightPercent(2.5)),

                                AnimatedTextField(
                                  controller: emailController,
                                  hintText: 'Email Address *',
                                  keyboardType: TextInputType.emailAddress,
                                  isRequired: true,
                                  validator: _validateEmail,
                                ),
                                AnimatedTextField(
                                  controller: passwordController,
                                  hintText: 'Create Password *',
                                  obscureText: true,
                                  isRequired: true,
                                  validator: _validatePassword,
                                ),
                                Obx(() {
                                  final errorMsg = authController.userRegisterErrorMsg;
                                  if (errorMsg.isEmpty) return const SizedBox.shrink();
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: context.heightPercent(0.5)),
                                    child: Text(
                                      errorMsg,
                                      style: TextStyle(
                                        fontSize: context.getResponsiveSize(3),
                                        color: Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }),
                                AnimatedTextField(
                                  controller: nameController,
                                  hintText: 'Full Name *',
                                  textCapitalization: TextCapitalization.words,
                                  isRequired: true,
                                  validator: _validateName,
                                ),
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
                                AnimatedTextField(
                                  controller: gstController,
                                  hintText: 'GST NO. *',
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  maxLength: 15,
                                  isRequired: true,
                                  validator: _validateGST,
                                ),

                                _buildCompactDropdownCard(
                                  hintText: 'State *',
                                  value: _selectedState,
                                  onTap: () {
                                    _showSearchSelectionBottomSheet(
                                      title: 'Select State',
                                      items: _indiaData.keys.toList()..sort(),
                                      onSelected: (val) {
                                        setState(() {
                                          _selectedState = val;
                                          _selectedCity = null;
                                          stateController.text = val;
                                          cityController.clear();
                                          _onFieldChanged();
                                        });
                                      },
                                    );
                                  },
                                ),
                                _buildCompactDropdownCard(
                                  hintText: 'City *',
                                  value: _selectedCity,
                                  onTap: () {
                                    if (_selectedState == null) {
                                      ToastUtils.showError(
                                        'Please select a state first',
                                      );
                                      return;
                                    }
                                    _showSearchSelectionBottomSheet(
                                      title: 'Select City',
                                      items: _indiaData[_selectedState]!,
                                      onSelected: (val) {
                                        setState(() {
                                          _selectedCity = val;
                                          cityController.text = val;
                                          _onFieldChanged();
                                        });
                                      },
                                    );
                                  },
                                ),

                                AnimatedTextField(
                                  controller: areaController,
                                  hintText: 'Area *',
                                  textCapitalization: TextCapitalization.words,
                                  isRequired: true,
                                  validator: (v) =>
                                      _validateRequired('Area', v),
                                ),
                                AnimatedTextField(
                                  controller: pincodeController,
                                  hintText: 'Pincode *',
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  isRequired: true,
                                  validator: _validatePincode,
                                ),
                                AnimatedTextField(
                                  controller: companyNameController,
                                  hintText: 'Company Name *',
                                  textCapitalization: TextCapitalization.words,
                                  isRequired: true,
                                  validator: (v) =>
                                      _validateRequired('Company Name', v),
                                ),

                                SizedBox(height: context.heightPercent(2)),

                                Text(
                                  'Staff Details (Optional)',
                                  style: TextStyle(
                                    fontSize: context.getResponsiveSize(3.8),
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                SizedBox(height: context.heightPercent(1)),

                                AnimatedTextField(
                                  controller: staffNameController,
                                  hintText: 'Staff Name',
                                  textCapitalization: TextCapitalization.words,
                                ),
                                AnimatedTextField(
                                  controller: staffPhoneController,
                                  hintText: 'Staff Phone Number',
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                ),

                                SizedBox(height: context.heightPercent(1)),

                                Obx(() {
                                  final isLoading =
                                      authController.userRegisterState ==
                                          CurrentAppState.LOADING ||
                                      _isSubmitting;

                                  return SizedBox(
                                    width: double.infinity,
                                    height: context.heightPercent(6),
                                    child: ElevatedButton(
                                      style: ButtonStyle(
                                        backgroundColor:
                                            WidgetStateProperty.resolveWith(
                                              (states) =>
                                                  states.contains(
                                                    WidgetState.disabled,
                                                  )
                                                  ? AppColors.primaryGold
                                                        .withValues(alpha: 0.35)
                                                  : AppColors.primaryGold,
                                            ),
                                        elevation:
                                            WidgetStateProperty.resolveWith(
                                              (states) =>
                                                  states.contains(
                                                    WidgetState.disabled,
                                                  )
                                                  ? 0
                                                  : 2,
                                            ),
                                        shape: WidgetStateProperty.all(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              context.getResponsiveSize(2.5),
                                            ),
                                          ),
                                        ),
                                      ),
                                      onPressed: (!_isFormValid || isLoading)
                                          ? null
                                          : _handleRegister,
                                      child: isLoading
                                          ? SizedBox(
                                              height: context.getResponsiveSize(
                                                5,
                                              ),
                                              width: context.getResponsiveSize(
                                                5,
                                              ),
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
                                SizedBox(height: context.heightPercent(2)),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account? ',
                                      style: TextStyle(
                                        fontSize: context.getResponsiveSize(
                                          3.5,
                                        ),
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          Get.offNamed(AppRoutes.login),
                                      child: Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: context.getResponsiveSize(
                                            3.5,
                                          ),
                                          color: AppColors.primaryGold,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: context.heightPercent(2)),

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
