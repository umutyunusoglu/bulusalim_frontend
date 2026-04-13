import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_identity_provider.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/application/providers/event_stream_provider.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/chat/message_entity.dart';
import 'package:outnest/domain/repositories/chat_repository.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/presentation/chat/view/components/chat_input_bar.dart';
import 'package:outnest/presentation/chat/view/components/chat_message_buble.dart';
import 'package:outnest/presentation/chat/view/components/chat_page_header.dart';

class ChatPage extends HookConsumerWidget {
  const ChatPage({required this.eventID, super.key});
  final String eventID;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatRepository = useMemoized(() => getIt<ChatRepository>());
    final scrollController = useScrollController();
    final currentUserId = ref.watch(currentUserIDProvider);
    final currentUser = ref.watch(currentUserEntityProvider).value;

    final eventAsync = ref.watch(eventStreamProvider(eventID));

    Future<void> handleSendMessage(String text) async {
      if (currentUser == null) return;
      final message = MessageEntity(
        content: text,
        senderID: currentUser.userID,
        username: currentUser.username,
        profileImageUrl: currentUser.profileImageUrl,
        createdAt: DateTime.now(),
      );
      await chatRepository.sendMessage(eventID, message);
      if (scrollController.hasClients) {
        unawaited(
          scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),
        );
      }
    }

    return eventAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Scaffold(
        body: Center(child: Text('Hata: $e')),
      ),
      data: (event) {
        if (event == null) {
          return const Scaffold(
            body: Center(child: Text('Buluşma bulunamadı')),
          );
        }

        final categoryIcon = event.hobbies.isNotEmpty
            ? (AppConfig.categories[event.hobbies.first] ?? '🎉')
            : '🎉';
        final creatorImage = event.creator.profileImageUrl.isNotEmpty
            ? event.creator.profileImageUrl
            : FileService.defaultProfileImageUrl();

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          body: Column(
            children: [
              ChatPageHeader(
                eventID: eventID,
                event: event,
                creatorID: event.creator.userID,
                chatTitle: event.name,
                creatorProfileImage: creatorImage,
                location: event.displayAddress.isNotEmpty
                    ? event.displayAddress
                    : 'Konum Yok',
                eventDate: event.startTime,
                participantStatus:
                    '${event.participants.length}/${event.capacity}',
                participantAvatars: event.participants,
                categoryIcon: categoryIcon,
              ),
              Expanded(
                child: StreamBuilder<List<MessageEntity>>(
                  stream: chatRepository.getChatMessagesStream(eventID),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final messages = snapshot.data ?? [];
                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          'Sohbeti başlat...',
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 14.sp,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      reverse: true,
                      padding: EdgeInsets.only(
                        left: 16.w,
                        right: 16.w,
                        top: 10.h,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderID == currentUserId;

                        var showDateDivider = false;
                        if (index == messages.length - 1) {
                          showDateDivider = true;
                        } else {
                          final prev = messages[index + 1];
                          if (message.createdAt.day != prev.createdAt.day ||
                              message.createdAt.month != prev.createdAt.month ||
                              message.createdAt.year != prev.createdAt.year) {
                            showDateDivider = true;
                          }
                        }

                        return Column(
                          children: [
                            if (showDateDivider)
                              _buildDateDivider(
                                _getFormattedDate(message.createdAt),
                              ),
                            ChatMessageBubble(
                              message: message.content,
                              time: DateFormat(
                                'HH:mm',
                              ).format(message.createdAt),
                              isCurrentUser: isMe,
                              username: isMe ? null : message.username,
                              userprofileImageUrl: isMe
                                  ? null
                                  : message.profileImageUrl,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              ChatInputBar(onSend: handleSendMessage),
            ],
          ),
        );
      },
    );
  }

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    if (dateToCheck == today) return 'Bugün';
    if (dateToCheck == yesterday) return 'Dün';
    return DateFormat('d MMMM yyyy', 'tr_TR').format(date);
  }

  Widget _buildDateDivider(String date) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        date,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
