import 'dart:ui';
import 'package:bulusalim/app_router.dart';
import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/core/constants/configs/app_config.dart';
import 'package:bulusalim/core/constants/theme/app_theme.dart';
import 'package:bulusalim/domain/services/session_service.dart';
import 'package:bulusalim/firebase_options.dart';
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
    // Emülatör ayarları
    FirebaseFirestore.instance.useFirestoreEmulator(AppConfig.host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(AppConfig.host, 9099);
    await FirebaseStorage.instance.useStorageEmulator(
      AppConfig.host,
      9199,
    );

    final authInstance = FirebaseAuth.instance;

    const testUserId = 'user4@example.com';

    if (testUserId == 'A') {
      if (authInstance.currentUser != null) {
        await authInstance.signOut();
      }

      await authInstance.signInAnonymously();
    } else {
      await authInstance.signInWithEmailAndPassword(
        email: testUserId,
        password: '123456',
      );
    }

    debugPrint("Current ${authInstance.currentUser?.email ?? "No user"}");
  } else {
    await FirebaseAppCheck.instance.activate();
  }

  await getItSetup();

  final sessionService = getIt<SessionService>();
  await sessionService.init();

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852), // Senin tasarım ölçülerin
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            // Klavyeyi kapatma işlemi (Aynen korundu)
            final currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus &&
                currentFocus.focusedChild != null) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
          },
          // MaterialApp -> MaterialApp.router
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: router,

            scrollBehavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
            ),
            theme: AppTheme.lightTheme,
            locale: const Locale('tr'),
            title: 'Buluşalım',

            builder: (context, widget) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.0),
                ),
                child: widget!,
              );
            },
          ),
        );
      },
    );
  }
}
