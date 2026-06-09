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

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController gstController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();

  final FocusNode stateFocusNode = FocusNode();
  final FocusNode cityFocusNode = FocusNode();

  String selectedCountryCode = "+91";
  bool isFormValid = false;

  // Starter dataset for India States & Cities
  final Map<String, List<String>> _indiaData = {
    "Andhra Pradesh": [
      "Visakhapatnam",
      "Vijayawada",
      "Guntur",
      "Nellore",
      "Tirupati",
    ],
    "Delhi": ["New Delhi", "North Delhi", "South Delhi", "Dwarka"],
    "Gujarat": [
      "Ahmedabad",
      "Surat",
      "Vadodara",
      "Rajkot",
      "Bhavnagar",
      "Jamnagar",
    ],
    "Karnataka": ["Bengaluru", "Mysuru", "Mangaluru", "Hubballi", "Belagavi"],
    "Maharashtra": [
      "Mumbai",
      "Pune",
      "Nagpur",
      "Thane",
      "Nashik",
      "Aurangabad",
    ],
    "Rajasthan": ["Jaipur", "Jodhpur", "Udaipur", "Kota", "Bikaner", "Ajmer"],
    "Tamil Nadu": [
      "Chennai",
      "Coimbatore",
      "Madurai",
      "Tiruchirappalli",
      "Salem",
    ],
    "Uttar Pradesh": [
      "Lucknow",
      "Kanpur",
      "Agra",
      "Varanasi",
      "Meerut",
      "Noida",
    ],
    "West Bengal": ["Kolkata", "Howrah", "Darjeeling", "Siliguri", "Asansol"],
  };

  void validateForm() {
    setState(() {
      isFormValid =
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
    stateController.addListener(validateForm);
    cityController.addListener(validateForm);
    areaController.addListener(validateForm);
    pincodeController.addListener(validateForm);
    companyNameController.addListener(validateForm);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    gstController.dispose();
    stateController.dispose();
    cityController.dispose();
    areaController.dispose();
    pincodeController.dispose();
    companyNameController.dispose();
    stateFocusNode.dispose();
    cityFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 400),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                          SizedBox(height: context.getScreenHeight(2)),

                          Text(
                            'Register',
                            style: TextStyle(
                              fontSize: context.getFontSize(6),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: context.getScreenHeight(0.5)),
                          Text(
                            'Create an account to continue',
                            style: TextStyle(
                              fontSize: context.getFontSize(3.5),
                              color: AppColors.textMuted,
                            ),
                          ),

                          SizedBox(height: context.getScreenHeight(2.5)),

                          // 1. EMAIL
                          AnimatedTextField(
                            controller: emailController,
                            hintText: 'Email Address *',
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
                            hintText: 'Create Password *',
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
                            hintText: 'Full Name *',
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
                            hintText: 'Enter Mobile Number *',
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              textStyle: TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w600,
                                fontSize: context.getFontSize(3.5).clamp(14.0, 28.0),
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
                            hintText: 'GST NO. *',
                            textCapitalization: TextCapitalization.characters,
                            isRequired: true,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'GST number is required'
                                : null,
                          ),

                          // 6. STATE (Autocomplete & Manual Entry) - 🔥 LayoutBuilder Removed!
                          RawAutocomplete<String>(
                            textEditingController: stateController,
                            focusNode: stateFocusNode,
                            optionsBuilder:
                                (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return const Iterable<String>.empty();
                                  }
                                  return _indiaData.keys.where((String option) {
                                    return option.toLowerCase().contains(
                                      textEditingValue.text.toLowerCase(),
                                    );
                                  });
                                },
                            onSelected: (String selection) {
                              cityController.clear();
                            },
                            fieldViewBuilder:
                                (
                                  context,
                                  textController,
                                  focusNode,
                                  onFieldSubmitted,
                                ) {
                                  return AnimatedTextField(
                                    controller: textController,
                                    focusNode: focusNode,
                                    hintText: 'State *',
                                    textCapitalization:
                                        TextCapitalization.words,
                                    isRequired: true,
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                        ? 'State is required'
                                        : null,
                                  );
                                },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  color: Colors.white,
                                  elevation: 8.0,
                                  borderRadius: BorderRadius.circular(16),
                                  child: ConstrainedBox(
                                    // 🔥 Sized using MediaQuery instead of LayoutBuilder
                                    constraints: BoxConstraints(
                                      maxHeight: 200,
                                      maxWidth:
                                          MediaQuery.of(context).size.width -
                                          context.getScreenWidth(10),
                                    ),
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                            final String option = options
                                                .elementAt(index);
                                            return InkWell(
                                              onTap: () => onSelected(option),
                                              child: Padding(
                                                padding: EdgeInsets.all(
                                                  context.getScreenWidth(4),
                                                ),
                                                child: Text(
                                                  option,
                                                  style: TextStyle(
                                                    color: AppColors.textDark,
                                                    fontSize: context
                                                        .getScreenWidth(3.5),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // 7. CITY (Dynamic Autocomplete based on State & Manual Entry) - 🔥 LayoutBuilder Removed!
                          RawAutocomplete<String>(
                            textEditingController: cityController,
                            focusNode: cityFocusNode,
                            optionsBuilder:
                                (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return const Iterable<String>.empty();
                                  }
                                  final currentState = stateController.text
                                      .trim();
                                  final citiesInState =
                                      _indiaData[currentState] ?? [];
                                  return citiesInState.where((String option) {
                                    return option.toLowerCase().contains(
                                      textEditingValue.text.toLowerCase(),
                                    );
                                  });
                                },
                            fieldViewBuilder:
                                (
                                  context,
                                  textController,
                                  focusNode,
                                  onFieldSubmitted,
                                ) {
                                  return AnimatedTextField(
                                    controller: textController,
                                    focusNode: focusNode,
                                    hintText: 'City *',
                                    textCapitalization:
                                        TextCapitalization.words,
                                    isRequired: true,
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                        ? 'City is required'
                                        : null,
                                  );
                                },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  color: Colors.white,
                                  elevation: 8.0,
                                  borderRadius: BorderRadius.circular(16),
                                  child: ConstrainedBox(
                                    // 🔥 Sized using MediaQuery instead of LayoutBuilder
                                    constraints: BoxConstraints(
                                      maxHeight: 200,
                                      maxWidth:
                                          MediaQuery.of(context).size.width -
                                          context.getScreenWidth(10),
                                    ),
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                            final String option = options
                                                .elementAt(index);
                                            return InkWell(
                                              onTap: () => onSelected(option),
                                              child: Padding(
                                                padding: EdgeInsets.all(
                                                  context.getScreenWidth(4),
                                                ),
                                                child: Text(
                                                  option,
                                                  style: TextStyle(
                                                    color: AppColors.textDark,
                                                    fontSize: context
                                                        .getScreenWidth(3.5),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // 8. AREA
                          AnimatedTextField(
                            controller: areaController,
                            hintText: 'Area *',
                            textCapitalization: TextCapitalization.words,
                            isRequired: true,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Area is required'
                                : null,
                          ),

                          // 9. PINCODE
                          AnimatedTextField(
                            controller: pincodeController,
                            hintText: 'Pincode *',
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            isRequired: true,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Pincode is required'
                                : null,
                          ),

                          // 10. COMPANY NAME
                          AnimatedTextField(
                            controller: companyNameController,
                            hintText: 'Company Name *',
                            textCapitalization: TextCapitalization.words,
                            isRequired: true,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Company Name is required'
                                : null,
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
                                  backgroundColor:
                                      WidgetStateProperty.resolveWith((states) {
                                        if (states.contains(
                                          WidgetState.disabled,
                                        )) {
                                          return AppColors.primaryGold
                                              .withValues(alpha: 0.35);
                                        }
                                        return AppColors.primaryGold;
                                      }),
                                  elevation: WidgetStateProperty.resolveWith((
                                    states,
                                  ) {
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
                                          // state: stateController.text.trim(), <-- Remember to add this in AuthController if saving state!
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
                                          fontSize: context.getFontSize(4),
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
                                  fontSize: context.getFontSize(3.5),
                                  color: AppColors.textMuted,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Get.offNamed(AppRoutes.login),
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: context.getFontSize(3.5),
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
                                fontSize: context.getFontSize(3),
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
      body: body,
    );
  }
}
