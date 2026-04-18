import 'package:flutter/material.dart';
import 'package:outnest/core/utils/types/enums/account_type_enum.dart';
import 'package:outnest/core/utils/types/enums/event_role_enum.dart';
import 'package:outnest/core/utils/types/enums/event_status_enum.dart';
import 'package:outnest/core/utils/types/enums/visibility_enum.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/presentation/camera/view/camera_page.dart';

class DebugCameraScreen extends StatelessWidget {
  const DebugCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraPage(
        event: EventEntity(
          eventID: 'debug-event-001',
          name: 'Akşam Yürüyüşü',
          city: 'İstanbul',
          hobbies: ['Yürüyüş', 'Doğa', 'Fotoğrafçılık'],
          creator: const EventParticipantEntity(
            userID: '',
            username: '',
            profileImageUrl: '',
            role: EventRoleEnum.creator,
            eventScore: 1,
            university: '',
          ),
          capacity: 10,
          participants: [],
          requestPool: [],
          status: EventStatusEnum.upcoming,
          rejectedUsers: [],
          startTime: DateTime.now().add(const Duration(hours: 1)),
          endTime: DateTime.now().add(const Duration(hours: 3)),
          location: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          displayAddress: 'Bağcılar, İstanbul',
          address: 'Bağcılar Mahallesi, İstanbul, Türkiye',
          participantCount: 4,
          isLocked: false,
          geohash: 'sxk3g',
          visibility: VisibilityEnum.university,
          showOnMap: true,
          accountType: AccountType.community,
        ),
      ),
    );
  }
}
