import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/core/utils/types/enums/screen_enum.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/presentation/shared/event_card/view/event_card.dart';

class EventPreviewScreen extends StatefulWidget {
  final String eventId;

  const EventPreviewScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<EventPreviewScreen> createState() => _EventPreviewScreenState();
}

class _EventPreviewScreenState extends State<EventPreviewScreen> {
  late Future<List<dynamic>> _eventDataFuture;
  @override
  void initState() {
    super.initState();
    _loadEventData();
  }

  @override
  void didUpdateWidget(covariant EventPreviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventId != widget.eventId) {
      _loadEventData();
    }
  }

  void _loadEventData() {
    final eventRepository = getIt<EventRepository>();
    _eventDataFuture = Future.wait([
      eventRepository.getEvent(widget.eventId),
      eventRepository.getEventParticipants(widget.eventId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
          ),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _eventDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load event: ${snapshot.error}'),
            );
          }

          final event = snapshot.data![0] as EventEntity?;
          final participants = snapshot.data![1] as List<CompactUserEntity>;
          if (event == null) {
            return const Center(child: Text('Event not found'));
          }

          return SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EventCard(
                    event: event,
                    participants: participants,
                    screen: ScreenEnum.eventPreview,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
