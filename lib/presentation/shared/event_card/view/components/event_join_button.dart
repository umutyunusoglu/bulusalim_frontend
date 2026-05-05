import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_event_providers.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_identity_provider.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/types/enums/screen_enum.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';
import 'package:outnest/presentation/shared/event_card/controllers/event_join_controller.dart';
import 'package:outnest/presentation/shared/popup.dart';

enum EventJoinButtonStyle {
  /// EventCard içindeki küçük buton (72x36)
  compact,
  expanded,
}

class EventJoinButton extends HookConsumerWidget {
  const EventJoinButton({
    required this.event,
    required this.screen,
    this.style = EventJoinButtonStyle.compact,
    super.key,
  });

  final EventEntity event;
  final ScreenEnum screen;
  final EventJoinButtonStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Controller'ı event başına bir kez oluştur, widget ağacından çıkınca temizle
    final controller = useMemoized(
      () => EventJoinController(event: event),
      [event.eventID],
    );

    // State hook'ları
    final activeEvents = ref.watch(upcomingAndOngoingEventsProvider);
    final isInActiveEvents = activeEvents.any(
      (e) => e.eventID == event.eventID,
    );
    final uid = ref.watch(currentUserIDProvider);
    if (uid == null) {
      return const SizedBox();
    }

    final externalStatus = isInActiveEvents
        ? EventJoinStatus.joined
        : _resolveStatusFromEvent(event, uid);

    final status = useState(externalStatus);
    final isProcessing = useState(false);

    useEffect(() {
      if (externalStatus == EventJoinStatus.joined) {
        status.value = EventJoinStatus.joined;
      }
      return null;
    }, [externalStatus]);

    // ─── AKSIYON HANDLERLARı ───

    Future<void> handleJoin() async {
      if (isProcessing.value) return;
      if (status.value != EventJoinStatus.canJoin) return;

      // Optimistic
      status.value = EventJoinStatus.pending;
      isProcessing.value = true;

      final error = await controller.requestJoin(screen: screen);

      isProcessing.value = false;

      if (error != null) {
        status.value = EventJoinStatus.canJoin;
        if (context.mounted) {
          showErrorPopup(context, message: error);
        }
      }
    }

    Future<void> handleWithdraw() async {
      if (isProcessing.value) return;

      // Optimistic
      status.value = EventJoinStatus.canJoin;
      isProcessing.value = true;

      final error = await controller.withdrawRequest();

      isProcessing.value = false;

      if (error != null) {
        status.value = EventJoinStatus.pending;
        if (context.mounted) {
          showErrorPopup(context, message: error);
        }
      }
    }

    void handleTap() {
      switch (status.value) {
        case EventJoinStatus.canJoin:
          handleJoin();
        case EventJoinStatus.pending:
          showDialog<void>(
            context: context,
            builder: (_) => Popup(
              title: 'Katılma isteğini geri almak istiyor musun?',
              description:
                  'İsteğini geri alırsan buluşma sahibi artık isteğini göremeyecek.',
              confirmButtonText: 'geri al',
              confirmButtonColor: const Color(0xFF1F415B),
              onConfirm: () {
                Navigator.of(context, rootNavigator: true).pop();
                handleWithdraw();
              },
            ),
          );
        case EventJoinStatus.joined:
          break;
      }
    }

    // ─── RENDER ───

    return GestureDetector(
      onTap: isProcessing.value ? null : handleTap,
      child: style == EventJoinButtonStyle.compact
          ? _buildCompact(status.value, isProcessing.value)
          : _buildExpanded(status.value, isProcessing.value),
    );
  }

  // ─── COMPACT (EventCard) ───

  Widget _buildCompact(EventJoinStatus status, bool isProcessing) {
    final width = 72.w;
    final height = 36.h;

    switch (status) {
      case EventJoinStatus.canJoin:
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                offset: Offset(0, 4),
                blurRadius: 4,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: isProcessing
              ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'katıl',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
        );

      case EventJoinStatus.pending:
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                offset: Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: isProcessing
              ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryColor,
                  ),
                )
              : Icon(
                  Icons.hourglass_empty_rounded,
                  color: AppColors.primaryColor,
                  size: 20.sp,
                ),
        );

      case EventJoinStatus.joined:
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                offset: Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'katıldın',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
        );
    }
  }

  // ─── EXPANDED (CommunityDetailView) ───

  Widget _buildExpanded(EventJoinStatus status, bool isProcessing) {
    switch (status) {
      case EventJoinStatus.canJoin:
        return _expandedContainer(
          color: AppColors.primaryColor,
          child: isProcessing
              ? SizedBox(
                  width: 22.w,
                  height: 22.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.confirmation_number_outlined,
                      color: Colors.white,
                      size: 22.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Buluşmaya Katıl',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        );

      case EventJoinStatus.pending:
        return _expandedContainer(
          color: Colors.white,
          borderColor: AppColors.primaryColor.withOpacity(0.3),
          shadowColor: Colors.black12,
          child: isProcessing
              ? SizedBox(
                  width: 22.w,
                  height: 22.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primaryColor,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.hourglass_empty_rounded,
                      color: AppColors.primaryColor,
                      size: 22.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'İstek Gönderildi · Geri Al',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
        );

      case EventJoinStatus.joined:
        return _expandedContainer(
          color: Colors.white,
          shadowColor: Colors.black12,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppColors.primaryColor,
                size: 22.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Katıldın',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _expandedContainer({
    required Color color,
    required Widget child,
    Color? borderColor,
    Color? shadowColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30.r),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1.2)
            : null,
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? AppColors.primaryColor.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

EventJoinStatus _resolveStatusFromEvent(EventEntity event, String uid) {
  if (uid.isEmpty) return EventJoinStatus.canJoin;
  if (event.participants.any((p) => p.userID == uid)) {
    return EventJoinStatus.joined;
  }
  if (event.requestPool.any((p) => p.userID == uid)) {
    return EventJoinStatus.pending;
  }
  return EventJoinStatus.canJoin;
}
