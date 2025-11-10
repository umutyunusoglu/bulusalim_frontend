import 'dart:io';
import 'dart:ui';
import 'package:bulusalim/application/providers/getIt_init.dart';
import 'package:bulusalim/core/constants/Configs/app_config.dart';
import 'package:bulusalim/components/navigator_bar.dart';
import 'package:bulusalim/core/constants/theme/app_theme.dart';
import 'package:bulusalim/domain/services/remote_config_service.dart';
import 'package:bulusalim/firebase_options.dart';
import 'package:bulusalim/screens/login/login_screen.dart';
import 'package:bulusalim/screens/register_screen.dart';
import 'package:bulusalim/screens/sign_in_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
    // webRecaptchaSiteKey: 'YOUR_RECAPTCHA_SITE_KEY',
  );

  if (kDebugMode) {
    // 1. Emülatörleri bağla
    FirebaseFirestore.instance.useFirestoreEmulator(AppConfig.host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(AppConfig.host, 9099);
    await FirebaseStorage.instance.useStorageEmulator(AppConfig.host, 9199);

    // 2. Önceki oturumu kapat
    final authInstance = FirebaseAuth.instance;
    if (authInstance.currentUser != null) {
      await authInstance.signOut();
    }
    // 3. Anonim olarak yeniden oturum aç
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      await authInstance.signOut();
    }
    await authInstance.signInAnonymously();

    // Debug amaçlı: Current User ID'sini konsola yazdır
    if (authInstance.currentUser != null) {
      print('Emülatörde Anonim Kullanıcı ID: ${authInstance.currentUser!.uid}');
    }
  }

  await getItSetup();

  final rc = getIt<RemoteConfigService>();
  final navbarOrder = await rc.getValue<String>("navbar_order");
  if (kDebugMode) {
    print("Remote Config Navbar Order: $navbarOrder");
  }

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      child: GestureDetector(
        onTap: () {
          final currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: MaterialApp(
          debugShowCheckedModeBanner: false,

          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
          ),
          theme: AppTheme.lightTheme,
          locale: const Locale('tr'),
          title: 'Flutter Demo',
          initialRoute: '/',
          routes: {
            '/': (context) => const SignInScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            // 🔸 Ana sayfa artık CustomNavBar ile
            '/home': (context) => CustomNavBar(),
          },
        ),
      ),
    );
  }
}
