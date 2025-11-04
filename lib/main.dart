import 'dart:io';
import 'dart:ui';
import 'package:bulusalim/core/constants/theme/app_theme.dart';
import 'package:bulusalim/screens/home/home_page.dart';
import 'package:bulusalim/screens/login/login_screen.dart';
import 'package:bulusalim/screens/register_screen.dart';
import 'package:bulusalim/screens/sign_in_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
/*
import 'package:bulusalim/screens/login/login_screen.dart';
import 'package:bulusalim/screens/register_screen.dart';
import 'package:bulusalim/screens/sign_in_screen.dart';
*/

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
            '/home': (context) => const HomePage(),
          },
        ),
      ),
    );
  }
}
