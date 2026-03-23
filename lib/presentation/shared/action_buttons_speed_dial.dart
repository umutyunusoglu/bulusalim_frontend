import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/domain/session_state.dart';

class ActionButtonsSpeedDial extends StatefulWidget {
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
  State<ActionButtonsSpeedDial> createState() => _ActionButtonsSpeedDialState();
}

class _ActionButtonsSpeedDialState extends State<ActionButtonsSpeedDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _shineController;

  final _sessionService = getIt<SessionService>();

  @override
  void initState() {
    super.initState();
    // Parlama hızı burada ayarlanır (2 saniyede bir döner)
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _checkAndRunAnimation();
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  void _checkAndRunAnimation() {
    final isUserInEvent = _sessionService.currentState.ongoingEvents.isNotEmpty;
    if (isUserInEvent) {
      _shineController.repeat();
    } else {
      _shineController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SessionState>(
      valueListenable: _sessionService.stateListenable,
      builder: (context, state, child) {
        final currentState = _sessionService.currentState;
        final isUserInEvent = currentState.ongoingEvents.isNotEmpty;
        // Animasyon kontrolünü burada yapıyoruz ama tasarımı etkilemiyoruz

        // QR Butonunun görünme şartı: Ya event'te olacak ya da zorla göster (Tutorial)
        final showQrButton = isUserInEvent || widget.forceShowAllButtons;

        _handleAnimation(isUserInEvent);

        return SpeedDial(
          openCloseDial: widget.isDialOpen,
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
          // Boyutları burada kesinleştiriyoruz
          buttonSize: const Size(64, 64),
          childrenButtonSize: const Size(64, 64),
          childMargin: const EdgeInsets.symmetric(vertical: 5),
          // Sadece İkon kısmını animasyonlu hale getiriyoruz ki buton iskeleti bozulmasın
          children: _buildChildren(context, showQrButton),
          child: AnimatedBuilder(
            animation: _shineController,
            builder: (context, _) => _buildShineIcon(isUserInEvent),
          ),
        );
      },
    );
  }

  // Boyut kaybını önlemek için Stack'i genişletiyoruz
  Widget _buildShineIcon(bool showShine) {
    return SizedBox(
      width: 64, // Butonun tam boyutuyla eşleşmeli
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ), // İkon boyutu netleşti
          if (showShine)
            Positioned.fill(
              // Parlamanın butonu taşırmamasını sağlar
              child: ClipOval(
                child: Transform.rotate(
                  angle: 0.5,
                  child: Transform.translate(
                    offset: Offset(-100 + (_shineController.value * 200), 0),
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

  void _handleAnimation(bool shouldAnimate) {
    if (shouldAnimate) {
      if (!_shineController.isAnimating) _shineController.repeat();
    } else {
      if (_shineController.isAnimating) _shineController.stop();
    }
  }

  List<SpeedDialChild> _buildChildren(
    BuildContext context,
    bool showQrButton,
  ) {
    return [
      _buildChild(
        icon: Icons.add_location_alt_outlined,
        iconColor: const Color(0xFF1B6A45),
        backgroundColor: const Color(0xFFD6EADA),
        onTap: widget.onLocationTap,
      ),
      _buildChild(
        icon: Icons.camera_alt_outlined,
        iconColor: const Color(0xFF165A72),
        backgroundColor: const Color(0xFFD1E4E8),
        onTap: widget.onCameraTap,
      ),
      if (showQrButton) // <-- ŞART GÜNCELLENDİ
        _buildChild(
          icon: Icons.qr_code_outlined,
          iconColor: AppColors.darkSecondaryColor,
          backgroundColor: AppColors.backgroundColor,
          onTap: () => widget.onQrTap(),
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
