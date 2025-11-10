import 'dart:io';
import 'dart:ui';
import 'package:bulusalim/application/providers/getIt_init.dart';
import 'package:bulusalim/core/constants/theme/app_theme.dart';
import 'package:bulusalim/firebase_options.dart';
import 'package:bulusalim/screens/home/home_page.dart';
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
/*
import 'package:bulusalim/screens/login/login_screen.dart';
import 'package:bulusalim/screens/register_screen.dart';
import 'package:bulusalim/screens/sign_in_screen.dart';
*/

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kDebugMode) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
  } else {
    await FirebaseAppCheck.instance.activate();
  }

  final String emulatorHost = kIsWeb
      ? 'localhost'
      : (Platform.isAndroid ? '10.0.2.2' : 'localhost');

  if (kDebugMode) {
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
    await FirebaseStorage.instance.useStorageEmulator(emulatorHost, 9199);
    await FirebaseAuth.instance.signInAnonymously();
  }

  getItSetup();

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
            '/home': (context) => const HomePage(),
          },
        ),
      ),
    );
  }
}
