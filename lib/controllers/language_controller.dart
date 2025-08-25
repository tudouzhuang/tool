import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends GetxController {
  var currentLanguage = 'English (US)'.obs;
  var currentLocale = const Locale('en', 'US').obs;

  @override
  void onInit() {
    super.onInit();
    loadSavedLanguage();
  }

  Future<void> loadSavedLanguage() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedLanguageCode = prefs.getString('language_code');
      String? savedCountryCode = prefs.getString('country_code');
      String? savedLanguageName = prefs.getString('language_name');

      if (savedLanguageCode != null && savedCountryCode != null && savedLanguageName != null) {
        currentLocale.value = Locale(savedLanguageCode, savedCountryCode);
        currentLanguage.value = savedLanguageName;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.updateLocale(currentLocale.value);
          _forceLayoutDirection();
        });
      }
    } catch (e) {
      print('Error loading saved language: $e');
    }
  }

  Future<void> changeLanguage(String languageCode, String countryCode, String languageName) async {
    try {
      currentLocale.value = Locale(languageCode, countryCode);
      currentLanguage.value = languageName;
      Get.updateLocale(currentLocale.value);
      _forceLayoutDirection();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', languageCode);
      await prefs.setString('country_code', countryCode);
      await prefs.setString('language_name', languageName);
    } catch (e) {
      print('Error changing language: $e');
    }
  }

  void _forceLayoutDirection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.context != null) {
        print('Layout direction forced to LTR for language: ${currentLanguage.value}');
      }
    });
  }

  bool get isCurrentLanguageRTL {
    return currentLocale.value.languageCode == 'ur' ||
        currentLocale.value.languageCode == 'ar' ||
        currentLocale.value.languageCode == 'fa';
  }

  List<Map<String, String>> get languageOptions => [
    {
      'name': 'English (US)',
      'code': 'en',
      'country': 'US',
    },
    {
      'name': 'English (UK)',
      'code': 'en',
      'country': 'GB',
    },
    {
      'name': 'Urdu',
      'code': 'ur',
      'country': 'PK',
    },
    {
      'name': 'Chinese',
      'code': 'zh',
      'country': 'CN',
    },
    {
      'name': 'German',
      'code': 'de',
      'country': 'DE',
    },
  ];
}