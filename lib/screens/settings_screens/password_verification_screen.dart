import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/custom_appbar.dart';

class VerifyPasswordScreen extends StatefulWidget {
  final VoidCallback onVerified;

  const VerifyPasswordScreen({
    super.key,
    required this.onVerified,
  });

  @override
  State<VerifyPasswordScreen> createState() => _VerifyPasswordScreenState();
}

class _VerifyPasswordScreenState extends State<VerifyPasswordScreen> {
  String _password = '';
  bool _isLoading = false;
  bool _isError = false;
  final AuthService _authService = AuthService();

  void _onNumberPressed(String number) {
    setState(() {
      if (_password.length < 4) {
        _password += number;
        _isError = false;
      }

      if (_password.length == 4) {
        _verifyPassword();
      }
    });
  }

  void _onDeletePressed() {
    setState(() {
      if (_password.isNotEmpty) {
        _password = _password.substring(0, _password.length - 1);
        _isError = false;
      }
    });
  }

  Future<void> _verifyPassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isValid = await _authService.verifyPassword(_password);
      if (isValid) {
        widget.onVerified();
      } else {
        setState(() {
          _isError = true;
          _password = '';
        });
        AppSnackBar.show(context, message: 'incorrect_password_try_again'.tr);
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _password = '';
      });
      AppSnackBar.show(context, message: 'error_verifying_password'.tr);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPasswordDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < _password.length
                ? _isError ? Colors.red : AppColors.primary
                : AppColors.t3SubHeading.withOpacity(0.3),
          ),
        );
      }),
    );
  }

  Widget _buildNumberButton(String number) {
    return GestureDetector(
      onTap: _isLoading ? null : () => _onNumberPressed(number),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withOpacity(_isLoading ? 0.1 : 0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            number,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _isLoading
                  ? AppColors.primary.withOpacity(0.3)
                  : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _onDeletePressed,
      child: SizedBox(
        width: 70,
        height: 70,
        child: Center(
          child: SvgPicture.asset(
            'assets/icons/password_delete_icon.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              _isLoading
                  ? AppColors.primary.withOpacity(0.3)
                  : AppColors.primary,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: 'verify_password'.tr,
        onBackPressed: () {
          Navigator.of(context).pop();
        },
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),
                Text(
                  'enter_4_digit_code'.tr,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'enter_password_access_locked_files'.tr,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 120),
                _buildPasswordDots(),
                const SizedBox(height: 30),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNumberButton('1'),
                        _buildNumberButton('2'),
                        _buildNumberButton('3'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNumberButton('4'),
                        _buildNumberButton('5'),
                        _buildNumberButton('6'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNumberButton('7'),
                        _buildNumberButton('8'),
                        _buildNumberButton('9'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(width: 70, height: 70),
                        _buildNumberButton('0'),
                        _buildDeleteButton(),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}