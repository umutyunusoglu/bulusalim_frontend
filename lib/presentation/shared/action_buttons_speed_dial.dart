import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/services/remote_config_service.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class ActionButtonsSpeedDial extends StatelessWidget {
  const ActionButtonsSpeedDial({
    super.key,
    required this.isDialOpen,
    required this.onCameraTap,
    required this.onLocationTap,
  });
  final ValueNotifier<bool> isDialOpen;
  final VoidCallback onCameraTap;
  final VoidCallback onLocationTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDialOpen,
      builder: (context, isOpen, _) {
        return SpeedDial(
          openCloseDial: isDialOpen,
          icon: Icons.add,
          activeIcon: Icons.close,
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          activeBackgroundColor: AppColors.primaryColor,
          activeForegroundColor: Colors.white,
          elevation: 8,
          spacing: 10,
          spaceBetweenChildren: 12,
          overlayColor: Colors.transparent,
          overlayOpacity: 0.0,

          // Ana buton boyutunu sabit tutma yerine Transform ile küçült
          buttonSize: const Size(64, 64),
          childrenButtonSize: const Size(64, 64),
          childMargin: const EdgeInsets.symmetric(
            vertical: 5,
          ), // çocuklar arasındaki boşluk
          // Küçültme animasyonu
          children: _buildChildren(context),
        );
      },
    );
  }

  List<SpeedDialChild> _buildChildren(BuildContext context) {
    return [
      _buildChild(
        icon: Icons.camera_alt_outlined,
        iconColor: const Color(0xFF165A72),
        backgroundColor: const Color(0xFFD1E4E8),
        onTap: onCameraTap,
      ),
      _buildChild(
        icon: Icons.add_location_alt_outlined,
        iconColor: const Color(0xFF1B6A45),
        backgroundColor: const Color(0xFFD6EADA),
        onTap: onLocationTap,
      ),
      _buildChild(
        icon: Icons.qr_code_outlined,
        iconColor: AppColors.darkSecondaryColor,
        backgroundColor: AppColors.backgroundColor,
        onTap: () {
          context.push('/my-qr');
        },
      ),
    ];
  }

  SpeedDialChild _buildChild({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return SpeedDialChild(
      shape: const CircleBorder(),
      child: Icon(icon, color: iconColor),
      backgroundColor: backgroundColor,
      elevation: 4,
      onTap: onTap,
    );
  }

  Future<void> _launchFeedback() async {
    String url;
    try {
      url = await getIt<RemoteConfigService>().getValue<String>('feedback_url');
    } catch (_) {
      url = 'https://outnest.app/';
    }

    await url_launcher.launchUrl(Uri.parse(url));
  }
}
