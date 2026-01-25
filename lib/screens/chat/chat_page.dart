import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/core/constants/configs/app_config.dart'; // <--- BU SATIR EKLENDİ
import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:bulusalim/core/utils/types/enums/event_status_enum.dart';
import 'package:bulusalim/domain/entities/chat/message_entity.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/repositories/chat_repository.dart';
import 'package:bulusalim/screens/chat/chat_input_bar.dart';
import 'package:bulusalim/screens/chat/chat_message_buble.dart';
import 'package:bulusalim/screens/chat/chat_page_header.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

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

  Map<String, String> _getSenderDetails(String senderID) {
    if (senderID == widget.creatorID) {
      return {
        'name': 'Buluşma Sahibi',
        'image': widget.creatorProfileImage.isNotEmpty
            ? widget.creatorProfileImage
            : 'https://picsum.photos/200',
      };
    }
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
          return {
            'name': (user['username'] as String?) ?? 'İsimsiz',
            'image': (user['profileImageUrl'] as String?) ?? '',
          };
        } else {
          return {
            'name': (user.username as String?) ?? 'İsimsiz',
            'image': (user.profileImageUrl as String?) ?? '',
          };
        }
      }
    } catch (e) {
      debugPrint('Kullanıcı bulma hatası: $e');
    }
    return {
      'name': 'Bilinmeyen Kullanıcı',
      'image': 'https://picsum.photos/200',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. HEADER
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('events')
                .doc(widget.eventID)
                .snapshots(),

            builder: (context, snapshot) {
              var displayTitle = widget.chatTitle;
              var displayLocation = widget.location;
              var displayDate = widget.eventDate;
              var displayCreatorImage = widget.creatorProfileImage;

              // 2. VARSAYILAN İKON TANIMLA
              String categoryIcon = '🎉';

              if (snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data != null) {
                  if (data.containsKey('name')) {
                    displayTitle = data['name'] as String;
                  }
                  if (data.containsKey('displayAddress')) {
                    displayLocation = data['displayAddress'] as String;
                  }

                  if (data.containsKey('startTime')) {
                    final timestamp = data['startTime'] as Timestamp?;
                    if (timestamp != null) displayDate = timestamp.toDate();
                  }

                  if (data.containsKey('creator') && data['creator'] is Map) {
                    final creatorMap = data['creator'] as Map<String, dynamic>;
                    if (creatorMap.containsKey('profileImageUrl')) {
                      displayCreatorImage =
                          creatorMap['profileImageUrl'] as String;
                    }
                  }

                  // 3. HOBİLERDEN İKONU AL
                  if (data.containsKey('hobbies')) {
                    final hobbies = data['hobbies'] as List<dynamic>?;
                    if (hobbies != null && hobbies.isNotEmpty) {
                      final category = hobbies.first.toString();
                      categoryIcon = AppConfig.categories[category] ?? '🎉';
                    }
                  }
                }
              }

              return ChatPageHeader(
                eventID: widget.eventID,
                event: widget.event,
                creatorID: widget.creatorID,
                chatTitle: displayTitle,
                creatorProfileImage: displayCreatorImage,
                location: displayLocation,
                eventDate: displayDate,
                participantStatus: widget.participantStatus,
                participantAvatars: widget.participantAvatars,
                categoryIcon: categoryIcon, // 4. KATEGORİ İKONUNU GÖNDER
              );
            },
          ),

          // 2. MESAJ LİSTESİ
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
