import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/domain/services/analytics/analytics_service.dart';
import 'package:outnest/domain/services/analytics/event_configs/send_event_invitation_analytics_config.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/usecases/send_event_invitation_usecase.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';
import 'package:outnest/presentation/shared/popup.dart';

void showUnfollowDialog(
  BuildContext context, {
  required String username,
  required String profileImageUrl,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder: (ctx) => Popup(
      title: '$username hesabını takip etmeyi bırakmak istediğine emin misin?',
      description:
          'Bu hesabı tekrardan takip etmek için istek tekrardan göndermen gerekecek.',
      confirmButtonText: 'takibi bırak',
      confirmButtonColor: const Color(0xFF5D6B82),
      onConfirm: () {
        ctx.pop();
        onConfirm();
      },
    ),
  );
}
