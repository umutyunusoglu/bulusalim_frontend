import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/presentation/chat/view/components/event_status_accordion_components/event_status_accordion_approved_row.dart';
import 'package:outnest/presentation/chat/view/components/event_status_accordion_components/event_status_accordion_pending_row.dart';

class EventStatusAccordion extends HookWidget {
  const EventStatusAccordion({
    required this.event,
    required this.pendingCount,
    super.key,
  });

  final EventEntity event;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final eventRepository = useMemoized(() => getIt<EventRepository>());

    final pendingUsers = useState<List<CompactUserEntity>>([]);
    final approvedUsers = useState<List<CompactUserEntity>>([]);

    useEffect(() {
      final approved = event.participants.toList()
        ..sort((a, b) {
          if (a.userID == event.creator.userID) return -1;
          if (b.userID == event.creator.userID) return 1;
          return 0;
        });
      approvedUsers.value = approved;
      pendingUsers.value = event.requestPool.toList();
      return null;
    }, [event]);

    Future<void> handleRequest(String userId, bool isAccepted) async {
      final index = pendingUsers.value.indexWhere((u) => u.userID == userId);
      if (index == -1) return;

      final user = pendingUsers.value[index];
      final updatedPending = [...pendingUsers.value]..removeAt(index);
      pendingUsers.value = updatedPending;

      if (isAccepted) {
        approvedUsers.value = [...approvedUsers.value, user];
      }

      try {
        if (isAccepted) {
          await eventRepository.acceptParticipant(event.eventID, user);
        } else {
          await eventRepository.rejectRequest(event.eventID, user);
        }
      } catch (e) {
        debugPrint('Update error: $e');
      }
    }

    Future<void> removeParticipant(String userId) async {
      final index = approvedUsers.value.indexWhere((u) => u.userID == userId);
      if (index == -1) return;

      final user = approvedUsers.value[index];
      approvedUsers.value = [...approvedUsers.value]..removeAt(index);

      try {
        await eventRepository.removeParticipant(event.eventID, user);
      } catch (e) {
        debugPrint('Remove error: $e');
      }
    }

    return Container(
      margin: EdgeInsets.only(top: 12.h),
      decoration: BoxDecoration(
        color: AppColors.accordionBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.transparent),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          childrenPadding: EdgeInsets.only(bottom: 12.h),
          iconColor: Colors.black87,
          collapsedIconColor: Colors.black87,
          onExpansionChanged: (_) {},
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Bekleyen İstekler ve Onaylı Katılımcılar',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (pendingCount > 0) ...[
                SizedBox(width: 8.w),
                Container(
                  width: 20.w,
                  height: 20.w,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    pendingCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          children: [
            Column(
              children: [
                ...pendingUsers.value.map(
                  (u) => EventStatusAccordionPendingRow(
                    user: u,
                    onAccept: () => handleRequest(u.userID, true),
                    onReject: () => handleRequest(u.userID, false),
                  ),
                ),
                ...approvedUsers.value.map(
                  (u) => EventStatusAccordionApprovedRow(
                    user: u,
                    isCreator: event.creator.userID == u.userID,
                    onRemove: () => removeParticipant(u.userID),
                  ),
                ),
                if (pendingUsers.value.isEmpty && approvedUsers.value.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Text(
                      'Henüz katılımcı yok.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12.sp,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
