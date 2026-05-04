import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/services/file_service.dart';

class EventStatusAccordionAvatar extends StatelessWidget {
  const EventStatusAccordionAvatar({
    required this.url,
    super.key,
  });

  final String url;

  @override
  Widget build(BuildContext context) {
    final hasValidUrl = url.isNotEmpty && url.startsWith('http');

    return Container(
      width: 36.w,
      height: 36.w,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(
        child: hasValidUrl
            ? CachedNetworkImage(
                imageUrl: fixEmulatorUrl(url),
                fadeInDuration: Duration.zero,
                fit: BoxFit.cover,
                placeholder: (c, u) => Container(color: AppColors.lightCloud),
                errorWidget: (c, u, e) => Image.asset(
                  FileService.defaultProfileImageUrl(),
                  fit: BoxFit.cover,
                ),
              )
            : Image.asset(
                FileService.defaultProfileImageUrl(),
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}
