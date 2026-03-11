import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/services/session_service.dart';

class ActionButtonsSpeedDial extends StatefulWidget {
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
    _checkAndRunAnimation();

    final isUserInEvent = _sessionService.currentState.ongoingEvents.isNotEmpty;
    return ValueListenableBuilder(
      valueListenable: _sessionService.stateListenable,
      builder: (context, state, child) {
        return AnimatedBuilder(
          animation: _shineController,
          builder: (context, child) {
            return SpeedDial(
              openCloseDial: widget.isDialOpen,
              // Ana buton ikonu yerine parlama efektli bir widget veriyoruz
              child: _buildShineIcon(),
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
              children: _buildChildren(context, isUserInEvent),
            );
          },
        );
      },
    );
  }

  // Parlama efektini oluşturan ana fonksiyon
  Widget _buildShineIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(Icons.add, color: Colors.white),
        ClipOval(
          child: SizedBox(
            width: 64,
            height: 64,
            child: Transform.rotate(
              angle: 0.5, // Parıltının açısı
              child: Transform.translate(
                offset: Offset(-100 + (_shineController.value * 200), 0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.05),
                        Colors.white.withOpacity(0.5),
                        Colors.white.withOpacity(0),
                      ],
                      stops: const [0.35, 0.5, 0.65],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<SpeedDialChild> _buildChildren(
    BuildContext context,
    bool isUserInEvent,
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
      if (isUserInEvent)
        _buildChild(
          icon: Icons.qr_code_outlined,
          iconColor: AppColors.darkSecondaryColor,
          backgroundColor: AppColors.backgroundColor,
          onTap: () => context.push('/my-qr'),
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
