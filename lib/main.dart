import 'dart:ui';
import 'package:bulusalim/app_router.dart';
import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/core/constants/configs/app_config.dart';
import 'package:bulusalim/core/constants/theme/app_theme.dart';
import 'package:bulusalim/domain/repositories/feed_repository.dart';
import 'package:bulusalim/domain/services/session_service.dart';
import 'package:bulusalim/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'
    show MapboxOptions;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Önce zaten var mı diye kontrol et
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      debugPrint('Firebase zaten başlatılmış (isEmpty kontrolü).');
    }
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      // Eğer "duplicate-app" hatası alırsak, Firebase zaten native tarafta başlamış demektir.
      // Bu hatayı görmezden gelip devam ediyoruz.
      debugPrint(
        'Firebase zaten native tarafta başlatılmış, işlem devam ediyor.',
      );
    } else {
      // Başka bir hata varsa fırlat
      rethrow;
    }
  } on Exception catch (e) {
    // Beklenmedik diğer hatalar için
    debugPrint('Firebase başlatma hatası (Generic): $e');
  }
  await dotenv.load();

  final mapBoxAccessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

  MapboxOptions.setAccessToken(mapBoxAccessToken);
  await getItSetup();

  await AppConfig.init();

  if (kDebugMode) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidDebugProvider(),
      providerApple: const AppleDebugProvider(),
    );

    print(AppConfig.host);
    // Emülatör ayarları
    FirebaseFirestore.instance.useFirestoreEmulator(
      AppConfig.host,
      8080,
      automaticHostMapping: false,
    );
    await FirebaseAuth.instance.useAuthEmulator(
      AppConfig.host,
      9099,
      automaticHostMapping: false,
    );
    await FirebaseStorage.instance.useStorageEmulator(
      AppConfig.host,
      9199,
      automaticHostMapping: false,
    );

    FirebaseFunctions.instance.useFunctionsEmulator(AppConfig.host, 5001);

    final authInstance = FirebaseAuth.instance;

    const testUserId = 'user1@test.com';

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

    debugPrint("Current ${authInstance.currentUser?.email ?? "No user"}");
  } else {
    await FirebaseAppCheck.instance.activate();
  }

  final sessionService = getIt<SessionService>();
  await sessionService.init();

  final feedRepository = getIt<FeedRepository>();
  await feedRepository.warmup();

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
