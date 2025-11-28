import 'dart:ui';
import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/core/constants/Configs/app_config.dart';
import 'package:bulusalim/core/constants/theme/app_theme.dart';
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

  if (kDebugMode) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidDebugProvider(),
      providerApple: const AppleDebugProvider(),
    );
    print(AppConfig.host);
    try {
      FirebaseFirestore.instance.useFirestoreEmulator(AppConfig.host, 8080);
      await FirebaseAuth.instance.useAuthEmulator(AppConfig.host, 9099);
      await FirebaseStorage.instance.useStorageEmulator(AppConfig.host, 9199);
    } catch (e) {
      print("Emülatör hatası (zaten başlatılmış olabilir): $e");
    }

    final authInstance = FirebaseAuth.instance;
    if (authInstance.currentUser == null) {
      await authInstance.signInAnonymously();
    }

    if (authInstance.currentUser != null) {
      print('Emülatörde Aktif Kullanıcı ID: ${authInstance.currentUser!.uid}');
    }
  } else {
    await FirebaseAppCheck.instance.activate();
  }

  await getItSetup();

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
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            final currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus &&
                currentFocus.focusedChild != null) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
          },
          child: MaterialApp(
            debugShowCheckedModeBanner: false,

            scrollBehavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
            ),
            theme: AppTheme.lightTheme,
            // Dark tema desteği eklersen:
            // darkTheme: AppTheme.darkTheme,
            // themeMode: ThemeMode.system,
            locale: const Locale('tr'),
            title: 'Buluşalım',
            initialRoute: '/',
            routes: {
              '/': (context) => const SignInScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
            },
          ),
        );
      },
    );
  }
}

// import 'dart:ui';
// import 'package:bulusalim/application/providers/get_it_init.dart';
// import 'package:bulusalim/core/constants/Configs/app_config.dart';
// import 'package:bulusalim/core/constants/theme/app_theme.dart';
// import 'package:bulusalim/firebase_options.dart';
// import 'package:bulusalim/screens/login/login_screen.dart';
// import 'package:bulusalim/screens/register_screen.dart';
// import 'package:bulusalim/screens/sign_in_screen.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_app_check/firebase_app_check.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

//   if (kDebugMode) {
//     await FirebaseAppCheck.instance.activate(
//       providerAndroid: const AndroidDebugProvider(),

//       providerApple: const AppleDebugProvider(),
//     );

//     print(AppConfig.host);
//     FirebaseFirestore.instance.useFirestoreEmulator(AppConfig.host, 8080);
//     await FirebaseAuth.instance.useAuthEmulator(AppConfig.host, 9099);
//     await FirebaseStorage.instance.useStorageEmulator(AppConfig.host, 9199);

//     final authInstance = FirebaseAuth.instance;
//     if (authInstance.currentUser != null) {
//       await authInstance.signOut();
//     }

//     await authInstance.signInAnonymously();

//     // Debug amaçlı: Current User ID'sini konsola yazdır
//     if (authInstance.currentUser != null) {
//       print('Emülatörde Anonim Kullanıcı ID: ${authInstance.currentUser!.uid}');
//     }
//   } else {
//     await FirebaseAppCheck.instance.activate();
//   }

//   await getItSetup();

//   runApp(const ProviderScope(child: MainApp()));
// }

// class MainApp extends StatelessWidget {
//   const MainApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ScreenUtilInit(
//       designSize: const Size(393, 852),
//       minTextAdapt: true,
//       splitScreenMode: true,
//       child: GestureDetector(
//         onTap: () {
//           final currentFocus = FocusScope.of(context);
//           if (!currentFocus.hasPrimaryFocus) {
//             currentFocus.unfocus();
//           }
//         },
//         child: MaterialApp(
//           debugShowCheckedModeBanner: false,

//           scrollBehavior: const MaterialScrollBehavior().copyWith(
//             dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
//           ),
//           theme: AppTheme.lightTheme,
//           locale: const Locale('tr'),
//           title: 'Flutter Demo',
//           initialRoute: '/',
//           routes: {
//             '/': (context) => const SignInScreen(),
//             '/login': (context) => const LoginScreen(),
//             '/register': (context) => const RegisterScreen(),
//           },
//         ),
//       ),
//     );
//   }
// }
