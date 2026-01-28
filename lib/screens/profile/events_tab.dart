import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/components/event_card.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/domain/services/session_service.dart';

class ProfileEventsTab extends StatelessWidget {
  const ProfileEventsTab({
    required this.currentEvents,
    required this.consideredEvents,
    this.isLoading = false,
    super.key,
  });
  final List<EventEntity> currentEvents;
  final List<EventEntity> consideredEvents;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final currentUser = getIt<SessionService>().currentUser;
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Column(
        children: [
          // --- BÖLÜM 1: GÜNCEL ETKİNLİKLER ---
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _buildSectionHeader(
              context,
              'Güncel Etkinlik',
              isActive: true,
            ),
          ),

          if (currentEvents.isNotEmpty)
            SizedBox(height: 0.h)
          else
            SizedBox(height: 16.h),

          if (currentEvents.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _buildEmptyState(
                context,
                'Henüz güncel bir etkinliğin yok.',
              ),
            )
          else
            ...currentEvents.map(
              (event) => EventCard(
                event: event,
                participants: event.participants,
              ),
            ),

          SizedBox(height: 8.h),

          // --- BÖLÜM 2: DÜŞÜNÜLEN ETKİNLİKLER ---
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _buildSectionHeader(
              context,
              'Düşünülen Etkinlikler',
              isActive: false,
            ),
          ),

          if (consideredEvents.isNotEmpty)
            SizedBox(height: 0.h)
          else
            SizedBox(height: 16.h),

          if (consideredEvents.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _buildEmptyState(
                context,
                'Henüz kaydettiğin bir etkinlik yok.',
              ),
            )
          else
            ...consideredEvents.map(
              (event) => EventCard(
                event: event,
                participants: event.participants,
              ),
            ),

          // Sayfa sonu boşluğu
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  // --- YARDIMCI WIDGET'LAR ---

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    required bool isActive,
  }) {
    // TEMA BAĞLANTISI
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary; // Turuncu
    final secondaryColor = theme.colorScheme.secondary; // Mavi

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        // Aktifse Primary'nin çok açık tonu, değilse hafif gri
        color: isActive
            ? primaryColor.withOpacity(0.12)
            : theme.disabledColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Urbanist',
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            // Aktifse Primary (Turuncu), değilse Secondary (Mavi)
            color: isActive ? primaryColor : secondaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: theme.disabledColor, // Gri yerine disabledColor
            fontSize: 14.sp,
            fontFamily: 'Urbanist',
          ),
        ),
      ),
    );
  }
}
