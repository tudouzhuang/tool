import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart'; // Add this import for .tr extension
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/custom_appbar.dart';

class SetPasswordScreen extends StatefulWidget {
  final bool isChanging;
  final bool isRecovery;
  final String? email;
  final String? userId;

  const SetPasswordScreen({
    super.key,
    this.isChanging = false,
    this.isRecovery = false,
    this.email,
    this.userId,
  });

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  String _password = '';
  String _confirmPassword = '';
  String _oldPassword = '';
  bool _isConfirming = false;
  bool _isEnteringOldPassword = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    if (widget.isChanging && !widget.isRecovery) {
      _isEnteringOldPassword = true;
    }
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (_isEnteringOldPassword) {
        if (_oldPassword.length < 4) {
          _oldPassword += number;
          if (_oldPassword.length == 4) {
            _verifyOldPassword();
          }
        }
      } else if (!_isConfirming) {
        if (_password.length < 4) {
          _password += number;
          if (_password.length == 4) {
            _isConfirming = true;
          }
        }
      } else {
        if (_confirmPassword.length < 4) {
          _confirmPassword += number;
          if (_confirmPassword.length == 4) {
            _handlePasswordConfirmation();
          }
        }
      }
    });
  }

  // Key fix for SetPasswordScreen - _setPassword method
  Future<void> _setPassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (widget.isRecovery && widget.userId != null) {
        success = await _authService.resetPasswordForUser(widget.userId!, _password);
      } else if (widget.isChanging && !widget.isRecovery) {
        success = await _authService.changePassword(_oldPassword, _password);
      } else {
        success = await _authService.savePassword(_password);
      }

      if (success) {
        // Notify parent screen of successful password operation
        Navigator.of(context).pop(true);
      } else {
        AppSnackBar.show(context, message: 'password_set_failed'.tr);
        _resetPasswordFields();
      }
    } catch (e) {
      AppSnackBar.show(context, message: '${'error'.tr}: ${e.toString()}');
      _resetPasswordFields();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOldPassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isValid = await _authService.verifyPassword(_oldPassword);
      if (isValid) {
        setState(() {
          _isEnteringOldPassword = false;
          _isLoading = false;
        });
      } else {
        AppSnackBar.show(
          context,
          message: 'incorrect_password'.tr,
        );
        setState(() {
          _oldPassword = '';
          _isLoading = false;
        });
      }
    } catch (e) {
      AppSnackBar.show(
        context,
        message: 'password_verification_error'.tr,
      );
      setState(() {
        _oldPassword = '';
        _isLoading = false;
      });
    }
  }

  void _handlePasswordConfirmation() {
    if (_password == _confirmPassword) {
      _setPassword();
    } else {
      AppSnackBar.show(
        context,
        message: 'passwords_do_not_match'.tr,
      );
      _resetPasswordFields();
    }
  }

  void _resetPasswordFields() {
    setState(() {
      _password = '';
      _confirmPassword = '';
      _isConfirming = false;
      if (widget.isChanging && !widget.isRecovery) {
        _oldPassword = '';
        _isEnteringOldPassword = true;
      }
    });
  }

  void _onDeletePressed() {
    setState(() {
      if (_isEnteringOldPassword) {
        if (_oldPassword.isNotEmpty) {
          _oldPassword = _oldPassword.substring(0, _oldPassword.length - 1);
        }
      } else if (!_isConfirming) {
        if (_password.isNotEmpty) {
          _password = _password.substring(0, _password.length - 1);
        }
      } else {
        if (_confirmPassword.isNotEmpty) {
          _confirmPassword =
              _confirmPassword.substring(0, _confirmPassword.length - 1);
        }
      }
    });
  }

  String _getCurrentTitle() {
    if (_isEnteringOldPassword) {
      return 'enter_current_password'.tr;
    } else if (_isConfirming) {
      return 'confirm_4_digit_code'.tr;
    } else {
      if (widget.isRecovery) {
        return 'set_new_4_digit_code'.tr;
      }
      return widget.isChanging
          ? 'set_new_4_digit_code'.tr
          : 'set_4_digit_code'.tr;
    }
  }

  String _getCurrentPassword() {
    if (_isEnteringOldPassword) {
      return _oldPassword;
    } else if (_isConfirming) {
      return _confirmPassword;
    } else {
      return _password;
    }
  }

  Widget _buildPasswordDots(String password) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < password.length
                ? AppColors.primary
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
        title: widget.isRecovery
            ? 'reset_password'.tr
            : widget.isChanging
            ? 'change_password'.tr
            : 'set_password'.tr,
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
                  _getCurrentTitle(),
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 120),
                _buildPasswordDots(_getCurrentPassword()),
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