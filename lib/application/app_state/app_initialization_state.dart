import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:outnest/domain/services/push_notifications_service.dart';
import 'package:outnest/domain/services/session_service.dart';

/// Pure observer — maps Firebase auth stream to bool.
/// Reactive: re-emits on sign-out, token revocation, etc.
final isUserLoggedInProvider = StreamProvider<bool>((ref) {
  return getIt<AuthService>().onAuthStateChanged.map((uid) => uid != null);
});

/// Pure observer — checks whether the logged-in user has a Firestore profile.
/// Auto-invalidated and re-run whenever isUserLoggedInProvider changes.
final isUserRegisteredProvider = FutureProvider<bool>((ref) async {
  final isLoggedIn = ref.watch(isUserLoggedInProvider).asData?.value;
  if (isLoggedIn != true) return false;
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return getIt<UserRepository>().isUserRegistered(uid);
});

/// Private coordinator — triggers service initialization when user is confirmed
/// logged in AND registered. Resets on logout to support re-initialization on
/// subsequent logins. ref.keepAlive() ensures this persists for the app lifetime.
final _appServicesCoordinator = Provider<void>((ref) {
  ref.keepAlive();
  var hasInitialized = false;

  Future<void> maybeInit() async {
    if (hasInitialized) return;
    if (ref.read(isUserRegisteredProvider).asData?.value != true) return;
    hasInitialized =
        true; // set before await — prevents double-init on re-entry
    await getIt<SessionService>().init();
    await getIt<PushNotificationsService>().initialize();
  }

  // Handles cold-start race: if isUserRegisteredProvider is already AsyncData(true)
  // when coordinator is created, ref.listen won't fire (no transition to observe).
  unawaited(Future.microtask(maybeInit));

  ref
    ..listen(isUserLoggedInProvider, (prev, next) {
      if (prev?.asData?.value == true && next.asData?.value == false) {
        hasInitialized = false;
      }
    })
    ..listen(isUserRegisteredProvider, (prev, next) => maybeInit());
});

/// Pure observer — returns true when SessionService has loaded the user's data,
/// which implies: logged in + registered + services initialized + data streamed.
/// Correctly toggles false on logout and back to true on re-login.
/// Activates _appServicesCoordinator by watching it.
final isAppInitialisedProvider = StreamProvider<bool>((ref) {
  ref.watch(_appServicesCoordinator); // ensures coordinator is active

  final service = getIt<SessionService>();
  final controller = StreamController<bool>.broadcast();

  void onStateChange() => controller.add(service.currentState.user != null);
  service.stateListenable.addListener(onStateChange);
  controller.add(service.currentState.user != null); // seed initial value

  ref.onDispose(() {
    service.stateListenable.removeListener(onStateChange);
    unawaited(controller.close());
  });

  return controller.stream;
});
