import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:outnest/application/app_state/app_initialization_state.dart';
import 'package:outnest/application/app_state/tutorial_providers.dart';

class InitScreen extends HookConsumerWidget {
  const InitScreen({
    super.key,
    this.nextPath,
  });

  final String? nextPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(isUserLoggedInProvider);
    final registeredState = ref.watch(isUserRegisteredProvider);
    final appInit = ref.watch(isAppInitialisedProvider);
    final tutorialSeen = ref.watch(tutorialSeenProvider); // YENİ

    final hasNavigated = useRef<bool>(false);
    final seenAuthLoading = useRef<bool>(false);

    useEffect(
      () {
        if (hasNavigated.value) return null;

        if (authState.isLoading) {
          seenAuthLoading.value = true;
          return null;
        }

        final isLoggedIn = authState.asData?.value;
        if (isLoggedIn == null) return null;

        if (!isLoggedIn) {
          if (!seenAuthLoading.value) return null;
          hasNavigated.value = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/welcome');
          });
          return null;
        }

        final isRegistered = registeredState.asData?.value;
        if (isRegistered == null) return null;

        if (!isRegistered) {
          hasNavigated.value = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/register-info');
          });
          return null;
        }

        if (appInit.asData?.value != true) return null;

        // YENİ: tutorial durumu henüz belli değilse bekle
        final seen = tutorialSeen.asData?.value;
        if (seen == null) return null;

        hasNavigated.value = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;

          // Deep link varsa tutorial'ı atla, direkt hedefe git
          if (nextPath != null &&
              nextPath!.isNotEmpty &&
              nextPath!.startsWith('/')) {
            context.go(nextPath!);
            return;
          }

          // YENİ: tutorial görülmediyse önce tutorial'a yönlendir
          context.go(seen ? '/home' : '/tutorial');
        });

        return null;
      },
      [authState, registeredState, appInit, tutorialSeen],
    ); // tutorialSeen eklendi

    if (appInit.hasError) {
      return Scaffold(
        body: Center(child: Text('Başlatma hatası: ${appInit.error}')),
      );
    }

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
