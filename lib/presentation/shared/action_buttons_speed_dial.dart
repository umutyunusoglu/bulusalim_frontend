import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:glowy_borders/glowy_borders.dart';
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
    required this.onIdeaTap,
    this.forceShowAllButtons = false,
    this.closedSize = 64,
    this.openSize = 44,
    this.childSpacing = 8,
  });

  final ValueNotifier<bool> isDialOpen;
  final VoidCallback onCameraTap;
  final VoidCallback onLocationTap;
  final VoidCallback onQrTap;
  final VoidCallback onIdeaTap;
  final bool forceShowAllButtons;
  final double closedSize;
  final double openSize;
  final double childSpacing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUserInEvent = ref.watch(isUserInOngoingEventProvider);
    final showQrButton = isUserInEvent || forceShowAllButtons;
    final isDialOpenValue = useValueListenable(isDialOpen);
    final showGlow = isUserInEvent && !isDialOpenValue;
    final layerLink = useMemoized(() => LayerLink());
    final overlayEntry = useRef<OverlayEntry?>(null);
    final buttonKey = useMemoized(() => GlobalKey());

    void removeOverlay() {
      overlayEntry.value?.remove();
      overlayEntry.value = null;
    }

    void showOverlay() {
      final renderBox =
          buttonKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final buttonPosition = renderBox.localToGlobal(Offset.zero);
      final buttonCenter =
          buttonPosition.dy + (renderBox.size.height / 2) - (closedSize / 2);

      final buttonCount = showQrButton ? 3 : 2;
      final totalHeight = (buttonCount * 64) + ((buttonCount - 1) * 8);

      final top = buttonCenter - childSpacing - totalHeight;
      final left =
          buttonPosition.dx + (renderBox.size.width / 2) - (closedSize / 2);

      overlayEntry.value = OverlayEntry(
        builder: (context) => Positioned(
          top: top,
          left: left,
          width: closedSize,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showQrButton) ...[
                _CustomDialChild(
                  icon: Icons.qr_code_outlined,
                  iconColor: AppColors.darkSecondaryColor,
                  backgroundColor: AppColors.backgroundColor,
                  onTap: () {
                    isDialOpen.value = false;
                    onQrTap();
                  },
                ),
                const SizedBox(height: 8),
              ],
              _CustomDialChild(
                icon: Icons.note_add_outlined,
                iconColor: AppColors.darkSlate,
                backgroundColor: AppColors.backgroundColor,
                onTap: onIdeaTap,
              ),
              const SizedBox(height: 8),
              _CustomDialChild(
                icon: Icons.add_location_alt_outlined,
                iconColor: const Color(0xFF1B6A45),
                backgroundColor: const Color(0xFFD6EADA),
                onTap: () {
                  isDialOpen.value = false;
                  onLocationTap();
                },
              ),
              const SizedBox(height: 8),
              _CustomDialChild(
                icon: Icons.camera_alt_outlined,
                iconColor: const Color(0xFF165A72),
                backgroundColor: const Color(0xFFD1E4E8),
                onTap: () {
                  isDialOpen.value = false;
                  onCameraTap();
                },
              ),
            ],
          ),
        ),
      );

      Overlay.of(context).insert(overlayEntry.value!);
    }

    useEffect(() {
      if (isDialOpenValue) {
        WidgetsBinding.instance.addPostFrameCallback((_) => showOverlay());
      } else {
        removeOverlay();
      }
      return null;
    }, [isDialOpenValue]);

    useEffect(() => removeOverlay, []);

    return CompositedTransformTarget(
      link: layerLink,
      child: GestureDetector(
        key: buttonKey,
        onTap: () => isDialOpen.value = !isDialOpen.value,
        child: SizedBox(
          width: closedSize,
          height: closedSize,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Glow — her zaman mount'ta kalır, sadece opacity değişir
              // Glow — her zaman mount'ta kalır, sadece opacity değişir
              AnimatedOpacity(
                opacity: showGlow ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: OverflowBox(
                  maxWidth: closedSize + 40,
                  maxHeight: closedSize + 40,
                  child: AnimatedGradientBorder(
                    borderSize: 4.5,
                    glowSize: 1,
                    animationTime: 6,
                    gradientColors: [
                      AppColors.primaryColor.withOpacity(0.5),
                      AppColors.primaryColor.withOpacity(0.2),
                      AppColors.primaryColor.withOpacity(0.5),
                    ],
                    borderRadius: BorderRadius.circular(110),
                    child: SizedBox(width: closedSize, height: closedSize),
                  ),
                ),
              ),
              // Ana buton
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: isDialOpenValue ? openSize : closedSize,
                  height: isDialOpenValue ? openSize : closedSize,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isDialOpenValue ? Icons.close : Icons.add,
                    color: Colors.white,
                    size: isDialOpenValue ? 20 : 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomDialChild extends StatelessWidget {
  const _CustomDialChild({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor),
      ),
    );
  }
}
