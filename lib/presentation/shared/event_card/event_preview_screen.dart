import 'package:flutter/material.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/utils/types/enums/screen_enum.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/presentation/shared/event_card/event_card.dart';

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
  late final Future<List<dynamic>> _eventDataFuture;
  @override
  void initState() {
    super.initState();
    final eventRepository = getIt<EventRepository>();

    _eventDataFuture = Future.wait([
      eventRepository.getEvent(widget.eventId),
      eventRepository.getEventParticipants(widget.eventId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event')),
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
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EventCard(
                      event: event,
                      participants: participants,
                      screen: ScreenEnum.eventPreview,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // simply pop back to the previous page (post page)
                        Navigator.of(context).pop();
                        // if using GoRouter, you could also use: context.pop();
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to post'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
