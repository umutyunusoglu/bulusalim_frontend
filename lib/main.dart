import 'dart:ui';
import 'package:outnest/app_router.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/constants/theme/app_theme.dart';
import 'package:outnest/domain/datasources/university_datasource.dart';
import 'package:outnest/domain/repositories/feed_repository.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // Eklendi
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'
    show MapboxOptions;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // 2. Crashlytics Entegrasyonu (Production için Kritik)
  // Flutter hatalarını Crashlytics'e bildirir.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Asenkron hataları yakalar (Platform channel hataları vb.)
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

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
  } else {
    // Release Modu (Production)
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity, // Android için standart
      appleProvider: AppleProvider.appAttest, // iOS için standart
    );
  }

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // 5. Servisleri Başlatma
  await FirebaseMessaging.instance.setAutoInitEnabled(true);

  final sessionService = getIt<SessionService>();
  await sessionService.init();

  // Session logunu sadece debug'da görelim, production loglarını kirletmeyelim
  if (kDebugMode) {
    debugPrint(
      'Oturum servisi başlatıldı. Durum: ${sessionService.currentUser != null ? "Giriş Var" : "Giriş Yok"}',
    );
  }

  final feedRepository = getIt<FeedRepository>();
  // Warmup işlemi hata verirse uygulama açılışını engellemesin diye try-catch bloğu eklenebilir
  try {
    await feedRepository.warmup();
  } catch (e, stack) {
    if (kDebugMode) debugPrint('Feed warmup hatası: $e');
    FirebaseCrashlytics.instance.recordError(e, stack);
  }

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
            // Klavyeyi kapatma mantığı
            final currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus &&
                currentFocus.focusedChild != null) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
          },
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false, // Banner kapalı
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
