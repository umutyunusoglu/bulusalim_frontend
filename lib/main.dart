import 'dart:ui';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'
    show MapboxOptions;
import 'package:outnest/app_router.dart';
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/constants/theme/app_theme.dart';
import 'package:outnest/domain/datasources/university_datasource.dart';
import 'package:outnest/firebase_options.dart';

// Test comment
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  // 1. Firebase Başlatma
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      debugPrint('Firebase zaten native tarafta başlatılmış.');
    } else {
      rethrow;
    }
  } catch (e) {
    debugPrint('Firebase başlatma hatası: $e');
  }

  FlutterError.onError = (details) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    } else {
      FirebaseCrashlytics.instance.recordFlutterError(details);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      print('Asenkron Hata: $error');
      return false;
    }

    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  await dotenv.load();

  final mapBoxAccessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
  MapboxOptions.setAccessToken(mapBoxAccessToken);

  await getItSetup();

  await AppConfig.init();

  // 3. App Check ve Emülatör Ayarları
  if (kDebugMode) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );

    /*
    FirebaseFirestore.instance.useFirestoreEmulator(
      AppConfig.host,
      8080,
    );
    await FirebaseStorage.instance.useStorageEmulator(
      AppConfig.host,
      9199,
      automaticHostMapping: false,
    );.
    FirebaseFunctions.instance.useFunctionsEmulator(AppConfig.host, 5001);
    FirebaseFirestore.instance.useFirestoreEmulator(AppConfig.host, 8080);

    final authInstance = FirebaseAuth.instance;
    await authInstance.useAuthEmulator(AppConfig.host, 9099);

    if (authInstance.currentUser != null) {
      debugPrint('Geliştirme modu: Eski oturum temizleniyor...');
      await authInstance.signOut();
    }

    const testUserId = 'user1@test.com';
""
    if (testUserId == 'A') {
      if (authInstance.currentUser != null) {
        await authInstance.signOut();
      }

      await authInstance.signInAnonymously();
    } else {
      await authInstance.signInWithEmailAndPassword(
        email: testUserId,
        password: 'password123',
      );
    }
    */
  } else {
    // Release Modu (Production)
    await FirebaseAppCheck.instance.activate(
      appleProvider: AppleProvider.appAttest, // iOS için standart
    );
  }

  // 5. Servisleri Başlatma
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  await FirebaseAuth.instance.initializeRecaptchaConfig();

  await GoogleSignIn.instance.initialize();

  getIt<UniversityDatasource>().initialize();

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
                  textScaler: TextScaler.noScaling,
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
