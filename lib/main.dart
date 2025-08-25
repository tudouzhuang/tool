import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolkit/controllers/language_controller.dart';
import 'package:toolkit/provider/certification_provider.dart';
import 'package:toolkit/provider/education_provider.dart';
import 'package:toolkit/provider/file_provider.dart';
import 'package:toolkit/provider/language_provider.dart';
import 'package:toolkit/provider/profile_provider.dart';
import 'package:toolkit/provider/saved_cv_provider.dart';
import 'package:toolkit/provider/skills_provider.dart';
import 'package:toolkit/provider/template_provider.dart';
import 'package:toolkit/provider/user_provider.dart';
import 'package:toolkit/provider/work_experience_provider.dart';
import 'package:toolkit/screens/onboarding_screen.dart';
import 'package:toolkit/screens/home_screen.dart';
import 'package:toolkit/screens/splash_screen/splash_screen.dart';
import 'package:toolkit/services/notification_service.dart';
import 'package:toolkit/utils/app_colors.dart';
import 'localization/language.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  await Hive.initFlutter();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TemplateProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => WorkExperienceProvider()),
        ChangeNotifierProvider(create: (context) => EducationProvider()),
        ChangeNotifierProvider(create: (context) => CertificationProvider()),
        ChangeNotifierProvider(create: (_) => SkillsProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => SavedCVProvider()),
        ChangeNotifierProvider(create: (_) => FileProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Toolkit App',
      debugShowCheckedModeBanner: false,
      translations: Language(),
      locale: _getStoredLocale(),
      fallbackLocale: const Locale('en', 'US'),

      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: child!,
        );
      },

      theme: ThemeData(
        primaryColor: const Color(0xFF00BFA5),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AppInitializer(),
    );
  }

  Locale? _getStoredLocale(){
    try{
      final controller = Get.put(LanguageController());
      return controller.currentLocale.value;
    } catch (e) {
      return null;
    }
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _showOnboarding = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await NotificationService.initialize(context);

      await _checkOnboardingStatus();
    } catch (e) {
      debugPrint('Error initializing app: $e');
    }
  }

  Future<void> _checkOnboardingStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    setState(() {
      _showOnboarding = !hasSeenOnboarding;
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}