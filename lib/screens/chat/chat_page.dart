import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/chat/message_entity.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/index.dart';
import 'package:outnest/domain/repositories/chat_repository.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/screens/chat/chat_input_bar.dart';
import 'package:outnest/screens/chat/chat_message_buble.dart';
import 'package:outnest/screens/chat/chat_page_header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

// NOT: Firestore importu kaldırıldı çünkü UI katmanında işi yok.

class ChatPage extends StatefulWidget {
  const ChatPage({
    required this.eventID,
    required this.event,
    required this.creatorID,
    required this.chatTitle,
    required this.participantAvatars,
    required this.location,
    required this.participantStatus,
    required this.eventDate,
    required this.creatorProfileImage,
    super.key,
  });

  final String eventID;
  final EventEntity event;
  final String creatorID;
  final String chatTitle;
  final List<dynamic> participantAvatars;
  final String location;
  final String participantStatus;
  final DateTime eventDate;
  final String creatorProfileImage;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
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

  String _getCategoryIcon() {
    var categoryIcon = '🎉';
    if (widget.event.hobbies.isNotEmpty) {
      final category = widget.event.hobbies.first;
      categoryIcon = AppConfig.categories[category] ?? '🎉';
    }
    return categoryIcon;
  }

  Map<String, String> _getSenderDetails(String senderID) {
    // Bu metod mantığına dokunulmadı, mevcut haliyle bırakıldı.
    var imagePath = '';
    var name = 'Bilinmeyen Kullanıcı';

    if (senderID == widget.creatorID) {
      name = 'Buluşma Sahibi';
      imagePath = widget.creatorProfileImage.isNotEmpty
          ? widget.creatorProfileImage
          : FileService.defaultProfileImageUrl();
    } else {
      try {
        final user = widget.participantAvatars.firstWhere(
          (u) {
            final uid = (u is Map) ? u['userID'] : u.userID;
            return uid == senderID;
          },
          orElse: () => null,
        );

        if (user != null) {
          if (user is Map) {
            name = (user['username'] as String?) ?? 'İsimsiz';
            imagePath =
                (user['profileImageUrl'] as String?) ??
                FileService.defaultProfileImageUrl();
          } else {
            // Eğer user bir Entity ise
            name = (user.username as String?) ?? 'İsimsiz';
            imagePath =
                (user.profileImageUrl as String?) ??
                FileService.defaultProfileImageUrl();
          }
        } else {
          imagePath = FileService.defaultProfileImageUrl();
        }
      } catch (e) {
        imagePath = FileService.defaultProfileImageUrl();
      }
    }

    return {
      'name': name,
      'image': imagePath,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          ChatPageHeader(
            eventID: widget.eventID,
            event: widget.event,
            creatorID: widget.creatorID,
            chatTitle: widget.chatTitle,
            creatorProfileImage: widget.creatorProfileImage,
            location: widget.location,
            eventDate: widget.eventDate,
            participantStatus: widget.participantStatus,
            participantAvatars: widget.participantAvatars,
            categoryIcon: _getCategoryIcon(), // Helper metoddan geliyor
          ),

          // 2. MESAJ LİSTESİ (Burası Clean Architecture'a uygun Repository Stream'i)
          Expanded(
            child: StreamBuilder<List<MessageEntity>>(
              stream: _chatRepository.getChatMessagesStream(
                widget.eventID,
              ), // Dokunulmadı
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
                    bottom: 0.h,
                    top: 10.h,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderID == currentUserId;

                    // --- Tarih Ayracı Mantığı Başlangıç ---
                    bool showDateDivider = false;

                    if (index == messages.length - 1) {
                      showDateDivider = true;
                    } else {
                      final prevMessage = messages[index + 1];
                      final currentMsgDate = message.createdAt;
                      final prevMsgDate = prevMessage.createdAt;

                      if (currentMsgDate.year != prevMsgDate.year ||
                          currentMsgDate.month != prevMsgDate.month ||
                          currentMsgDate.day != prevMsgDate.day) {
                        showDateDivider = true;
                      }
                    }

                    final String dateDividerString = _getFormattedDate(
                      message.createdAt,
                    );
                    // --- Tarih Ayracı Mantığı Bitiş ---

                    final timeString = DateFormat(
                      'HH:mm',
                    ).format(message.createdAt);

                    String? username;
                    String? profileImageUrl;

                    if (!isMe) {
                      username = message.username;
                      profileImageUrl = message.profileImageUrl;
                    }

                    return Column(
                      children: [
                        if (showDateDivider)
                          _buildDateDivider(dateDividerString),
                        ChatMessageBubble(
                          message: message.content,
                          time: timeString,
                          isCurrentUser: isMe,
                          username: username,
                          userprofileImageUrl: profileImageUrl,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // 3. INPUT ALANI
          ChatInputBar(
            onSend: (text) => _handleSendMessage(text),
          ),
        ],
      ),
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
