import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/core/errors/exceptions/auth_exceptions.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';

Future<void> handleSocialLogin({
  required BuildContext context,
  required TaskEither<AuthException, String> Function() signIn,
  required String providerName,
}) async {
  final result = await signIn().run();

  if (!context.mounted) return;

  switch (result) {
    case Right():
      context.go('/splash');
    case Left(value: AuthCancelledException()):
      break;
    case Left(value: AuthNotFoundException(:final message)):
      showErrorPopup(context, message: message);
    case Left(value: final _):
      showErrorPopup(
        context,
        message: '$providerName ile giriş yapılamadı. Lütfen tekrar deneyiniz.',
      );
  }
}
