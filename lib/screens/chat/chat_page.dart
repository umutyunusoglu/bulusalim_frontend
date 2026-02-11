import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/chat/message_entity.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/repositories/chat_repository.dart';
import 'package:outnest/domain/services/file_service.dart';
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
    final message = MessageEntity(
      content: text,
      senderID: currentUserId,
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

  // Helper metod: Kategori ikonunu Entity üzerinden bulur
  String _getCategoryIcon() {
    var categoryIcon = '🎉';
    // EventEntity içinde hobbies listesi olduğunu varsayıyoruz (önceki kodda map['hobbies'] vardı)
    // Eğer EventEntity içinde hobbies yoksa burayı entity yapısına göre güncellemelisin.
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
          // 1. HEADER (ARTIK STREAM DEĞİL, STATİK WIDGET)
          // Verileri doğrudan widget parametrelerinden alıyoruz.
          ChatPageHeader(
            eventID: widget.eventID,
            event: widget.event,
            creatorID: widget.creatorID,
            chatTitle:
                widget.chatTitle, // Stream'den gelen 'displayTitle' yerine
            creatorProfileImage:
                widget.creatorProfileImage, // Tekrar fetch etmeye gerek yok
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

                    if (message.content.toLowerCase().contains('bildirim') ||
                        message.content.toLowerCase().contains('katıldı')) {
                      return _buildSystemMessage(message.content);
                    }

                    final timeString = DateFormat(
                      'HH:mm',
                    ).format(message.createdAt);

                    String? username;
                    String? avatarUrl;

                    if (!isMe) {
                      final details = _getSenderDetails(message.senderID);
                      username = details['name'];
                      avatarUrl = details['image'];
                    }

                    return ChatMessageBubble(
                      message: message.content,
                      time: timeString,
                      isCurrentUser: isMe,
                      username: username,
                      userAvatarUrl: avatarUrl,
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

  Widget _buildSystemMessage(String content) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Center(
        child: Text(
          content,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textGrey.withOpacity(0.6),
            fontSize: 11.sp,
            fontFamily: 'SF Pro Display',
          ),
        ),
      ),
    );
  }
}
