import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:outnest/domain/services/push_notifications_service.dart';
import 'package:outnest/domain/services/session_service.dart';

class InitScreen extends StatefulWidget {
  const InitScreen({Key? key}) : super(key: key);

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> with RouteAware {
  // Kontrolün birden fazla kez üst üste tetiklenmesini engellemek için flag
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // İlk açılışta çalıştır
    _initializeApp();
  }

  // Sayfa her odağa geldiğinde (Geri dönüldüğünde vb.) tetiklenir
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Eğer sayfa şu an aktifse ve bir işlem yürütülmüyorsa tekrar kontrol et
    if (!_isProcessing) {
      _initializeApp();
    }
  }

  Future<void> _initializeApp() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    final authService = getIt<AuthService>();
    final userRepository = getIt<UserRepository>();
    final pushService = getIt<PushNotificationsService>();
    final sessionService = getIt<SessionService>();

    try {
      // Temel servisleri her seferinde valide et
      await sessionService.init();
      await pushService.initialize();

      final isLoggedIn = await authService.isUserLoggedIn();

      if (!isLoggedIn) {
        if (mounted) context.go('/welcome');
      } else {
        final userId = authService.getCurrentUserID();
        final isUserRegistered = await userRepository.isUserRegistered(userId);

        if (isUserRegistered) {
          // İstediğin session yenileme metodu her başarılı girişte/dönüşte çalışır
          await sessionService.refreshSession();
          if (mounted) context.go('/home');
        } else {
          // Kullanıcı login ama register değilse register'a yönlendir
          if (mounted) context.go('/register-info');
        }
      }
    } catch (e) {
      debugPrint("Init Error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
