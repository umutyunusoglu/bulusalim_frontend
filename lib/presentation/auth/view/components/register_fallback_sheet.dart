import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:outnest/presentation/auth/controllers/auth_status_enum.dart';
import 'package:outnest/presentation/auth/controllers/handle_social_signin.dart';
import 'package:outnest/presentation/auth/view/components/apple_auth_button.dart';
import 'package:outnest/presentation/auth/view/components/google_auth_button.dart';

Future<void> showRegisterFallbackSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const RegisterFallbackSheet(),
  );
}

class RegisterFallbackSheet extends HookWidget {
  const RegisterFallbackSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final authStatus = useState(AuthStatus.none);
    final isAnyLoading = authStatus.value != AuthStatus.none;

    Future<void> handleSignIn({
      required AuthStatus status,
      required bool isGoogle,
    }) async {
      if (isAnyLoading) return;
      authStatus.value = status;

      await handleSocialSignIn(
        context: context,
        signIn: () => isGoogle
            ? getIt<AuthService>().signInWithGoogle(isLogin: false)
            : getIt<AuthService>().signInWithApple(isLogin: false),
        providerName: isGoogle ? 'Google' : 'Apple',
      );

      if (context.mounted) authStatus.value = AuthStatus.none;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 32.h),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Başka bir yöntemle kayıt olmak ister misin?',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Şu an sunucularda bir yoğunluk yaşanıyor olabilir. '
              'Telefon numaranız ile kayıt olurken problem yaşıyorsanız '
              'lütfen diğer yöntemleri deneyin. Aksaklık nedeniyle özür dileriz.',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.h),
            GoogleAuthButton(
              isLoading: authStatus.value == AuthStatus.google,
              isDisabled: isAnyLoading,
              onTap: () => handleSignIn(
                status: AuthStatus.google,
                isGoogle: true,
              ),
            ),
            if (Platform.isIOS) ...[
              SizedBox(height: 12.h),
              AppleAuthButton(
                isLoading: authStatus.value == AuthStatus.apple,
                isDisabled: isAnyLoading,
                onTap: () => handleSignIn(
                  status: AuthStatus.apple,
                  isGoogle: false,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
