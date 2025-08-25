import 'package:flutter/material.dart';
import '../models/user_model_1.dart';
import '../models/website_model.dart';

class UserProvider extends ChangeNotifier {
  final UserModel _userData = UserModel();
  List<Website> _websites = [];

  UserModel get userData => _userData;
  List<Website> get websites => _websites;

  void loadUserData({
    required UserModel userData,
    List<Website>? websites,
  }) {
    debugPrint('UserProvider: loadUserData called');
    debugPrint('User data: ${userData.fullName}, ${userData.email}');
    debugPrint('Websites: ${websites?.map((w) => '${w.name}: ${w.url}').toList()}');

    _userData.fullName = userData.fullName;
    _userData.designation = userData.designation;
    _userData.email = userData.email;
    _userData.phoneNumber = userData.phoneNumber;
    _userData.profileImagePath = userData.profileImagePath;
    _userData.careerObjective = userData.careerObjective;
    _userData.websiteUrl = userData.websiteUrl;

    if (websites != null) {
      _websites = List<Website>.from(websites);
      debugPrint('Websites loaded: ${_websites.length} items');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
      debugPrint('UserProvider: loadUserData completed, notifyListeners called');
    });
  }

  void updateUserData({
    String? fullName,
    String? designation,
    String? email,
    String? phoneNumber,
    String? profileImagePath,
    String? careerObjective,
    String? websiteUrl,
  }) {
    debugPrint('UserProvider: updateUserData called');
    debugPrint('Parameters: fullName=$fullName, email=$email, websiteUrl=$websiteUrl');

    if (fullName != null) _userData.fullName = fullName;
    if (designation != null) _userData.designation = designation;
    if (email != null) _userData.email = email;
    if (phoneNumber != null) _userData.phoneNumber = phoneNumber;
    if (profileImagePath != null) _userData.profileImagePath = profileImagePath;
    if (careerObjective != null) _userData.careerObjective = careerObjective;
    if (websiteUrl != null) _userData.websiteUrl = websiteUrl;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
      debugPrint('UserProvider: updateUserData completed');
    });
  }

  void updateCareerObjective(String objective) {
    debugPrint('UserProvider: updateCareerObjective called with: $objective');
    _userData.careerObjective = objective;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void updateWebsite(String? url) {
    debugPrint('UserProvider: updateWebsite called with: $url');
    _userData.websiteUrl = url;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void updateWebsites(List<Website> websites) {
    debugPrint('Updating websites with ${websites.length} items');
    _websites = List<Website>.from(websites);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<Map<String, dynamic>> getWebsitesAsMaps() {
    return _websites.map((website) => website.toMap()).toList();
  }

  void clearUserData() {
    debugPrint('UserProvider: clearUserData called');
    _userData.fullName = null;
    _userData.designation = null;
    _userData.email = null;
    _userData.phoneNumber = null;
    _userData.profileImagePath = null;
    _userData.careerObjective = null;
    _userData.websiteUrl = null;
    _websites = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
      debugPrint('UserProvider: clearUserData completed');
    });
  }
}