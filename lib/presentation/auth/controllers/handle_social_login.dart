import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/errors/exceptions/auth_exceptions.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';

Future<void> handleSocialLogin({
  required BuildContext context,
  required TaskEither<AuthException, String> Function() signIn,
  required String providerName,
}) async {
  final result = await signIn().run();
  final _logger = getIt<LoggingService>();

  if (!context.mounted) return;

  switch (result) {
    case Right():
      context.go('/splash');
    case Left(value: AuthCancelledException()):
      break;
    case Left(value: AuthNotFoundException(:final message)):
      _logger.error(
        '$providerName ile giriş yapılamadı: ${result.value.message}',
        error: result.value,
      );
      showErrorPopup(context, message: message);
    case Left(value: final _):
      _logger.error(
        '$providerName ile giriş yapılamadı: ${result.value.message}',
        error: result.value,
      );

      showErrorPopup(
        context,
        message: '$providerName ile giriş yapılamadı.',
      );
  }
}
