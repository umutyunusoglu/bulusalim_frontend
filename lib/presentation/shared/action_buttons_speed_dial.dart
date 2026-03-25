import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_event_providers.dart';

import 'package:outnest/core/constants/theme/color_themes.dart';

class ActionButtonsSpeedDial extends HookConsumerWidget {
  const ActionButtonsSpeedDial({
    super.key,
    required this.isDialOpen,
    required this.onCameraTap,
    required this.onLocationTap,
    required this.onQrTap,
    this.forceShowAllButtons = false,
  });

  final ValueNotifier<bool> isDialOpen;
  final VoidCallback onCameraTap;
  final VoidCallback onLocationTap;
  final VoidCallback onQrTap;
  final bool forceShowAllButtons;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUserInEvent = ref.watch(isUserInOngoingEventProvider);
    final showQrButton = isUserInEvent || forceShowAllButtons;

    final shineController = useAnimationController(
      duration: const Duration(seconds: 2),
    );

    // isUserInEvent değiştiğinde animasyonu başlat/durdur
    if (isUserInEvent) {
      if (!shineController.isAnimating) shineController.repeat();
    } else {
      if (shineController.isAnimating) shineController.stop();
    }

    return SpeedDial(
      openCloseDial: isDialOpen,
      activeChild: const Icon(Icons.close, color: Colors.white),
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      activeBackgroundColor: AppColors.primaryColor,
      activeForegroundColor: Colors.white,
      elevation: 8,
      spacing: 6,
      spaceBetweenChildren: 8,
      overlayColor: Colors.transparent,
      overlayOpacity: 0.0,
      buttonSize: const Size(64, 64),
      childrenButtonSize: const Size(64, 64),
      childMargin: const EdgeInsets.symmetric(vertical: 5),
      children: _buildChildren(context, showQrButton),
      child: AnimatedBuilder(
        animation: shineController,
        builder: (context, _) =>
            _buildShineIcon(isUserInEvent, shineController),
      ),
    );
  }

  Widget _buildShineIcon(bool showShine, AnimationController controller) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.add, color: Colors.white, size: 28),
          if (showShine)
            Positioned.fill(
              child: ClipOval(
                child: Transform.rotate(
                  angle: 0.5,
                  child: Transform.translate(
                    offset: Offset(-100 + (controller.value * 200), 0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.4),
                            Colors.white.withOpacity(0.0),
                          ],
                          stops: const [0.3, 0.5, 0.7],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<SpeedDialChild> _buildChildren(BuildContext context, bool showQrButton) {
    return [
      _buildChild(
        icon: Icons.add_location_alt_outlined,
        iconColor: const Color(0xFF1B6A45),
        backgroundColor: const Color(0xFFD6EADA),
        onTap: onLocationTap,
      ),
      _buildChild(
        icon: Icons.camera_alt_outlined,
        iconColor: const Color(0xFF165A72),
        backgroundColor: const Color(0xFFD1E4E8),
        onTap: onCameraTap,
      ),
      if (showQrButton)
        _buildChild(
          icon: Icons.qr_code_outlined,
          iconColor: AppColors.darkSecondaryColor,
          backgroundColor: AppColors.backgroundColor,
          onTap: onQrTap,
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
}
