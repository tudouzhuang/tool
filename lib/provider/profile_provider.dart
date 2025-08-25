import 'package:flutter/material.dart';

class ProfileProvider extends ChangeNotifier {
  String? _selectedAvatar;
  String? _username;
  String? _email;
  String? _gender;
  String? _dateOfBirth;
  String? _phoneNumber;

  ProfileProvider() {
    // Initialize with default values including avatar 6
    _selectedAvatar = '6'; // Set default avatar to 6
    _gender = 'Not set';
    _dateOfBirth = 'Not set';
  }

  String? get selectedAvatar => _selectedAvatar;
  String? get username => _username;
  String? get email => _email;
  String? get gender => _gender;
  String? get dateOfBirth => _dateOfBirth;
  String? get phoneNumber => _phoneNumber;

  void loadProfileData({
    String? avatar,
    String? username,
    String? email,
    String? gender,
    String? dateOfBirth,
    String? phoneNumber,
  }) {
    _selectedAvatar = avatar ?? '6'; // Default to avatar 6 if null
    _username = username;
    _email = email;
    _gender = gender ?? 'Not set';
    _dateOfBirth = dateOfBirth ?? 'Not set';
    _phoneNumber = phoneNumber;
    notifyListeners();
  }

  void updateAvatar(String avatarPath) {
    _selectedAvatar = avatarPath;
    notifyListeners();
  }

  void updateUsername(String username) {
    _username = username;
    notifyListeners();
  }

  void updateEmail(String email) {
    _email = email;
    notifyListeners();
  }

  void updateGender(String gender) {
    _gender = gender;
    notifyListeners();
  }

  void updateDateOfBirth(String dateOfBirth) {
    _dateOfBirth = dateOfBirth;
    notifyListeners();
  }

  void updatePhoneNumber(String phoneNumber) {
    _phoneNumber = phoneNumber;
    notifyListeners();
  }

  void updateProfile({
    String? avatar,
    String? username,
    String? email,
    String? gender,
    String? dateOfBirth,
    String? phoneNumber,
  }) {
    if (avatar != null) _selectedAvatar = avatar;
    if (username != null) _username = username;
    if (email != null) _email = email;
    if (gender != null) _gender = gender;
    if (dateOfBirth != null) _dateOfBirth = dateOfBirth;
    if (phoneNumber != null) _phoneNumber = phoneNumber;
    notifyListeners();
  }

  void clearProfile() {
    _selectedAvatar = '6';
    _username = null;
    _email = null;
    _gender = 'Not set';
    _dateOfBirth = 'Not set';
    _phoneNumber = null;
    notifyListeners();
  }
}