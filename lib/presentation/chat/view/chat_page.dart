import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/application/providers/event_stream_provider.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/chat/message_entity.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/index.dart';
import 'package:outnest/domain/repositories/chat_repository.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/presentation/chat/view/components/chat_input_bar.dart';
import 'package:outnest/presentation/chat/view/components/chat_message_buble.dart';
import 'package:outnest/presentation/chat/view/components/chat_page_header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({required this.eventID, super.key});
  final String eventID;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  late final ChatRepository _chatRepository;
  final ScrollController _scrollController = ScrollController();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  UserEntity? currentUser = getIt<SessionService>().currentUser;

  @override
  void initState() {
    super.initState();
    _chatRepository = getIt<ChatRepository>();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSendMessage(String text) async {
    if (currentUser == null) return;
    final message = MessageEntity(
      content: text,
      senderID: currentUser!.userID,
      username: currentUser!.username,
      profileImageUrl: currentUser!.profileImageUrl,
      createdAt: DateTime.now(),
    );
    await _chatRepository.sendMessage(widget.eventID, message).then((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- LIVE EVENT VERİSİ ---
    final eventAsync = ref.watch(eventStreamProvider(widget.eventID));

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
                eventID: widget.eventID,
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
                  stream: _chatRepository.getChatMessagesStream(widget.eventID),
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
                      controller: _scrollController,
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

                        bool showDateDivider = false;
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
              ChatInputBar(onSend: _handleSendMessage),
            ],
          ),
        );
      },
    );
  }

  // Tarihi "Bugün", "Dün" veya "11 Şubat" şeklinde formatlar
  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Bugün';
    } else if (dateToCheck == yesterday) {
      return 'Dün';
    } else {
      return DateFormat('d MMMM yyyy', 'tr_TR').format(date);
    }
  }

  // Tarih ayracı tasarımı
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
