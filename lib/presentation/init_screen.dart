import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:outnest/application/app_state/app_initialization_state.dart';

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

    // Persists across rebuilds without triggering a rebuild when mutated.
    // Guards against double navigation if providers re-emit after navigation starts.
    final hasNavigated = useRef<bool>(false);

    // Tracks whether auth state has gone through AsyncLoading since this instance
    // mounted. On cold start, StreamProvider always starts as AsyncLoading. After
    // login, the provider already has a value (AsyncData(false)) and jumps directly
    // to AsyncData(true) via a platform-channel event — never going through
    // AsyncLoading. Without this guard, InitScreen would see the stale false value
    // and incorrectly redirect to /welcome before the login state propagates.
    final seenAuthLoading = useRef<bool>(false);

    useEffect(() {
      if (hasNavigated.value) return null;

      // Step 1: auth state must be known
      if (authState.isLoading) {
        seenAuthLoading.value = true;
        return null;
      }

      final isLoggedIn = authState.asData?.value;
      if (isLoggedIn == null) return null;

      if (!isLoggedIn) {
        // Guard: only route to /welcome if auth state was freshly resolved from
        // AsyncLoading. If seenAuthLoading is false, this is a stale AsyncData(false)
        // from before login — wait for the real auth event to arrive.
        if (!seenAuthLoading.value) return null;

        hasNavigated.value = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go('/welcome');
        });
        return null;
      }

      // Step 2: registration status must be known
      final isRegistered = registeredState.asData?.value;
      if (isRegistered == null) return null;

      if (!isRegistered) {
        hasNavigated.value = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go('/register-info');
        });
        return null;
      }

      // Step 3: wait for app services to initialize and user data to load
      if (appInit.asData?.value != true) return null;

      hasNavigated.value = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final destination =
            (nextPath != null &&
                nextPath!.isNotEmpty &&
                nextPath!.startsWith('/'))
            ? nextPath!
            : '/home';
        context.go(destination);
      });

      return null;
    }, [authState, registeredState, appInit]);

    if (appInit.hasError) {
      return Scaffold(
        body: Center(child: Text('Başlatma hatası: ${appInit.error}')),
      );
    }

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
