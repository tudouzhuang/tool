import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toolkit/screens/settings_screens/set_password_screen.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/buttons/gradient_btn.dart';
import '../../widgets/custom_appbar.dart';

class PhoneRecoveryScreen extends StatefulWidget {
  const PhoneRecoveryScreen({super.key});

  @override
  State<PhoneRecoveryScreen> createState() => _PhoneRecoveryScreenState();
}

class _PhoneRecoveryScreenState extends State<PhoneRecoveryScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (index) => FocusNode());

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isOtpSent = false;
  String? _foundUserId;
  String _selectedCountryCode = '+1';
  String? _errorMessage;

  // List of supported country codes
  final List<Map<String, String>> _countryCodes = [
    {'code': '+1', 'name': 'United States', 'flag': '🇺🇸'},
    {'code': '+1', 'name': 'Canada', 'flag': '🇨🇦'},
    {'code': '+44', 'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'code': '+91', 'name': 'India', 'flag': '🇮🇳'},
    {'code': '+92', 'name': 'Pakistan', 'flag': '🇵🇰'},
    {'code': '+93', 'name': 'Afghanistan', 'flag': '🇦🇫'},
    {'code': '+33', 'name': 'France', 'flag': '🇫🇷'},
    {'code': '+49', 'name': 'Germany', 'flag': '🇩🇪'},
    {'code': '+86', 'name': 'China', 'flag': '🇨🇳'},
    {'code': '+81', 'name': 'Japan', 'flag': '🇯🇵'},
    {'code': '+82', 'name': 'South Korea', 'flag': '🇰🇷'},
    {'code': '+61', 'name': 'Australia', 'flag': '🇦🇺'},
    {'code': '+7', 'name': 'Russia', 'flag': '🇷🇺'},
    {'code': '+55', 'name': 'Brazil', 'flag': '🇧🇷'},
    {'code': '+52', 'name': 'Mexico', 'flag': '🇲🇽'},
    {'code': '+34', 'name': 'Spain', 'flag': '🇪🇸'},
    {'code': '+39', 'name': 'Italy', 'flag': '🇮🇹'},
    {'code': '+90', 'name': 'Turkey', 'flag': '🇹🇷'},
    {'code': '+20', 'name': 'Egypt', 'flag': '🇪🇬'},
    {'code': '+27', 'name': 'South Africa', 'flag': '🇿🇦'},
    {'code': '+966', 'name': 'Saudi Arabia', 'flag': '🇸🇦'},
    {'code': '+971', 'name': 'UAE', 'flag': '🇦🇪'},
    {'code': '+62', 'name': 'Indonesia', 'flag': '🇮🇩'},
    {'code': '+60', 'name': 'Malaysia', 'flag': '🇲🇾'},
    {'code': '+65', 'name': 'Singapore', 'flag': '🇸🇬'},
    {'code': '+66', 'name': 'Thailand', 'flag': '🇹🇭'},
    {'code': '+84', 'name': 'Vietnam', 'flag': '🇻🇳'},
    {'code': '+63', 'name': 'Philippines', 'flag': '🇵🇭'},
    {'code': '+880', 'name': 'Bangladesh', 'flag': '🇧🇩'},
    {'code': '+94', 'name': 'Sri Lanka', 'flag': '🇱🇰'},
    {'code': '+977', 'name': 'Nepal', 'flag': '🇳🇵'},
    {'code': '+98', 'name': 'Iran', 'flag': '🇮🇷'},
    {'code': '+964', 'name': 'Iraq', 'flag': '🇮🇶'},
    {'code': '+972', 'name': 'Israel', 'flag': '🇮🇱'},
    {'code': '+31', 'name': 'Netherlands', 'flag': '🇳🇱'},
    {'code': '+32', 'name': 'Belgium', 'flag': '🇧🇪'},
    {'code': '+41', 'name': 'Switzerland', 'flag': '🇨🇭'},
    {'code': '+43', 'name': 'Austria', 'flag': '🇦🇹'},
    {'code': '+45', 'name': 'Denmark', 'flag': '🇩🇰'},
    {'code': '+46', 'name': 'Sweden', 'flag': '🇸🇪'},
    {'code': '+47', 'name': 'Norway', 'flag': '🇳🇴'},
    {'code': '+48', 'name': 'Poland', 'flag': '🇵🇱'},
    {'code': '+351', 'name': 'Portugal', 'flag': '🇵🇹'},
    {'code': '+30', 'name': 'Greece', 'flag': '🇬🇷'},
    {'code': '+234', 'name': 'Nigeria', 'flag': '🇳🇬'},
    {'code': '+254', 'name': 'Kenya', 'flag': '🇰🇪'},
    {'code': '+256', 'name': 'Uganda', 'flag': '🇺🇬'},
    {'code': '+255', 'name': 'Tanzania', 'flag': '🇹🇿'},
    {'code': '+233', 'name': 'Ghana', 'flag': '🇬🇭'},
    {'code': '+212', 'name': 'Morocco', 'flag': '🇲🇦'},
    {'code': '+213', 'name': 'Algeria', 'flag': '🇩🇿'},
    {'code': '+216', 'name': 'Tunisia', 'flag': '🇹🇳'},
    {'code': '+218', 'name': 'Libya', 'flag': '🇱🇾'},
    {'code': '+54', 'name': 'Argentina', 'flag': '🇦🇷'},
    {'code': '+56', 'name': 'Chile', 'flag': '🇨🇱'},
    {'code': '+57', 'name': 'Colombia', 'flag': '🇨🇴'},
    {'code': '+51', 'name': 'Peru', 'flag': '🇵🇪'},
    {'code': '+58', 'name': 'Venezuela', 'flag': '🇻🇪'},
    {'code': '+593', 'name': 'Ecuador', 'flag': '🇪🇨'},
    {'code': '+595', 'name': 'Paraguay', 'flag': '🇵🇾'},
    {'code': '+598', 'name': 'Uruguay', 'flag': '🇺🇾'},
    {'code': '+591', 'name': 'Bolivia', 'flag': '🇧🇴'},
  ];

  List<Map<String, String>> _filteredCountryCodes = [];

  @override
  void initState() {
    super.initState();
    _filteredCountryCodes = List.from(_countryCodes);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _searchController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'recover_your_account'.tr;
      });
      return;
    }

    if (!_validatePhoneNumber(_phoneController.text.trim())) {
      final minLength = _getMinLengthForCountry(_selectedCountryCode);
      final maxLength = _getMaxLengthForCountry(_selectedCountryCode);
      setState(() {
        _errorMessage =
            'Please enter a valid phone number ($minLength-$maxLength digits)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fullPhoneNumber =
          '$_selectedCountryCode${_phoneController.text.trim()}';
      final userId = await _authService.findUserByPhoneNumber(fullPhoneNumber);

      if (userId == null) {
        setState(() {
          _errorMessage = 'no_account_found'.tr;
          _isLoading = false;
        });
        return;
      }

      _foundUserId = userId;
      final success = await _authService.sendOTP(fullPhoneNumber);

      if (success) {
        setState(() {
          _isOtpSent = true;
          _isLoading = false;
        });
        AppSnackBar.show(context, message: 'otp_sent'.tr);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'Failed to send OTP';
      switch (e.code) {
        case 'invalid-phone-number':
          errorMessage = 'Invalid phone number format';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later';
          break;
        case 'app-not-authorized':
          errorMessage = 'App not authorized for phone verification';
          break;
        default:
          errorMessage = e.message ?? 'Failed to send OTP';
      }

      setState(() {
        _errorMessage = errorMessage;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  Future<void> _verifyOtp() async {
    String otpCode =
        _otpControllers.map((controller) => controller.text).join();

    if (otpCode.length != 6) {
      setState(() {
        _errorMessage = 'invalid_otp'.tr;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = await _authService.verifyOTPForPasswordReset(otpCode);

      if (userId != null) {
        // Clear OTP fields
        for (var controller in _otpControllers) {
          controller.clear();
        }

        // Navigate to SetPasswordScreen for password reset, passing the userId
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SetPasswordScreen(
              isRecovery: true,
              email: null,
              userId: userId,
            ),
          ),
        );

        // If password was successfully reset, pop back
        if (result == true) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to verify OTP';
        });
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Invalid OTP';
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'The verification code entered is invalid';
          break;
        case 'session-expired':
          errorMessage =
              'The verification session has expired. Please request a new OTP';
          break;
        default:
          errorMessage = e.message ?? 'Failed to verify OTP';
      }

      setState(() {
        _errorMessage = errorMessage;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fullPhoneNumber =
          '$_selectedCountryCode${_phoneController.text.trim()}';
      final success =
          await _authService.sendOTP(fullPhoneNumber, isResend: true);

      if (success) {
        AppSnackBar.show(context, message: 'otp_resent'.tr);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to resend OTP';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  void _showCountryCodePicker() {
    _filteredCountryCodes = List.from(_countryCodes);
    _searchController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'select_country_code'.tr,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),

                  // Search Field
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        textSelectionTheme: TextSelectionThemeData(
                          cursorColor: AppColors.primary,
                          selectionColor: AppColors.primary.withOpacity(0.3),
                          selectionHandleColor: AppColors.primary,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'search_country'.tr,
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.primary),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            _filterCountries(value);
                          });
                        },
                      ),
                    ),
                  ),

                  // Country List
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredCountryCodes.length,
                      itemBuilder: (context, index) {
                        final country = _filteredCountryCodes[index];
                        final isSelected =
                            country['code'] == _selectedCountryCode;

                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: AppColors.primary.withOpacity(0.1),
                          leading: Text(
                            country['flag']!,
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            country['name']!,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: const Color(0xFF1F2937),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                country['code']!,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ],
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _selectedCountryCode = country['code']!;
                              _errorMessage = null;
                            });
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

  void _filterCountries(String query) {
    if (query.isEmpty) {
      _filteredCountryCodes = List.from(_countryCodes);
    } else {
      _filteredCountryCodes = _countryCodes.where((country) {
        final name = country['name']!.toLowerCase();
        final code = country['code']!.toLowerCase();
        final searchQuery = query.toLowerCase();

        return name.contains(searchQuery) ||
            code.contains(searchQuery) ||
            code.replaceAll('+', '').contains(searchQuery);
      }).toList();
    }
  }

  bool _validatePhoneNumber(String phone) {
    phone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final minLength = _getMinLengthForCountry(_selectedCountryCode);
    final maxLength = _getMaxLengthForCountry(_selectedCountryCode);
    return phone.length >= minLength && phone.length <= maxLength;
  }

  int _getMinLengthForCountry(String countryCode) {
    switch (countryCode) {
      case '+1':
        return 10;
      case '+44':
        return 10;
      case '+91':
        return 10;
      case '+92':
        return 10;
      case '+86':
        return 11;
      case '+7':
        return 10;
      default:
        return 7;
    }
  }

  int _getMaxLengthForCountry(String countryCode) {
    switch (countryCode) {
      case '+1':
        return 10;
      case '+44':
        return 11;
      case '+91':
        return 10;
      case '+92':
        return 10;
      case '+86':
        return 11;
      case '+7':
        return 10;
      default:
        return 15;
    }
  }

  String _getPhoneHint(String countryCode) {
    switch (countryCode) {
      case '+1':
        return '(555) 000-0000';
      case '+44':
        return '7911 123456';
      case '+91':
        return '98765 43210';
      case '+92':
        return '300 1234567';
      case '+33':
        return '6 12 34 56 78';
      case '+49':
        return '171 2345678';
      case '+86':
        return '138 0013 8000';
      case '+81':
        return '90 1234 5678';
      case '+61':
        return '4 1234 5678';
      case '+55':
        return '11 91234-5678';
      case '+7':
        return '912 345-67-89';
      case '+966':
        return '50 123 4567';
      case '+971':
        return '50 123 4567';
      case '+234':
        return '802 123 4567';
      case '+62':
        return '812-3456-7890';
      default:
        return 'Enter phone number';
    }
  }

  String _getCountryFlag(String countryCode) {
    final country = _countryCodes.firstWhere(
      (c) => c['code'] == countryCode,
      orElse: () => {'flag': '🌍'},
    );
    return country['flag']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: !_isOtpSent ? 'phone_recovery'.tr : 'verify_otp'.tr,
        onBackPressed: () {
          Navigator.of(context).pop(false);
        },
      ),
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isOtpSent) _buildPhoneVerifySection(),
                    if (_isOtpSent) _buildOtpVerifySection(),
                  ],
                ),
              ),
            ),

            // Bottom Button Container
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: _buildBottomButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    String buttonText = 'continue'.tr;
    VoidCallback? onPressed = _sendOtp;

    if (_isOtpSent) {
      buttonText = 'verify'.tr;
      onPressed = _verifyOtp;
    }

    return CustomGradientButton(
      text: buttonText,
      onPressed: onPressed,
    );
  }

  Widget _buildPhoneVerifySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'recover_your_account'.tr,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 40),
        Text(
          'enter_phone_to_recover'.tr,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6B6B6B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 40),
        Text(
          'phone_number'.tr,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF1A1A1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        // Phone Number Input
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 8,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Row(
            children: [
              // Country Code Dropdown
              InkWell(
                onTap: _showCountryCodePicker,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getCountryFlag(_selectedCountryCode),
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedCountryCode,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: const Color(0xFF1F2937),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF6B7280),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              // Phone Number Input
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: TextSelectionThemeData(
                      cursorColor: AppColors.primary,
                      selectionColor: AppColors.primary.withOpacity(0.3),
                      selectionHandleColor: AppColors.primary,
                    ),
                  ),
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    cursorColor: AppColors.primary,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(15),
                    ],
                    decoration: InputDecoration(
                      hintText: _getPhoneHint(_selectedCountryCode),
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFFA0A0A0),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.inter(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildOtpVerifySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'verify_your_phone'.tr,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 40),
        RichText(
          text: TextSpan(
            text: 'enter_code_sent'.tr,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B6B6B),
              height: 1.4,
            ),
            children: [
              TextSpan(
                text: '$_selectedCountryCode${_phoneController.text}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // OTP Input Fields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _otpControllers[index].text.isNotEmpty
                      ? AppColors.gradientStart
                      : const Color(0xFFE0E0E0),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: TextSelectionThemeData(
                    cursorColor: AppColors.primary,
                    selectionColor: AppColors.primary.withOpacity(0.3),
                    selectionHandleColor: AppColors.primary,
                  ),
                ),
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  cursorColor: AppColors.primary,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  onChanged: (value) => _onOtpChanged(value, index),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 30),

        // Resend Section
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "no_code_received".tr,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6B6B6B),
                ),
              ),
              GestureDetector(
                onTap: _isLoading ? null : _resendOtp,
                child: Text(
                  'resend'.tr,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isLoading ? Colors.grey : AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }
}
