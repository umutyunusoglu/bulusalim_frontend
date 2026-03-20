import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';

PreferredSizeWidget buildAppBar(BuildContext context, {bool showBack = true}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: showBack
        ? IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.darkSlate,
            ),
            onPressed: () {
              context.pop();
            },
          )
        : null,
    actions: [
      IconButton(
        icon: const Icon(Icons.close, color: AppColors.darkSlate),
        onPressed: () {
          context.pop();
        },
      ),
    ],
  );
}
