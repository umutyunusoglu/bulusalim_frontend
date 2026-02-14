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

  // SessionService'ten gelen entity (nullable)
  UserEntity? currentUserEntity = getIt<SessionService>().currentUser;

  @override
  void initState() {
    super.initState();
    _chatRepository = getIt<ChatRepository>();
    // currentUserEntity runtime'da değişebiliyorsa (ör. async yükleniyorsa)
    // dinleme ekleyebilirsiniz; burada getIt üzerinden anlık alıyoruz.
    currentUserEntity = getIt<SessionService>().currentUser;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSendMessage(String text) async {
    // Güvenlik: currentUserEntity null ise gönderme yapma
    final cu = getIt<SessionService>().currentUser ?? currentUserEntity;
    if (cu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı bilgisi yüklenemedi. Mesaj gönderilemiyor.'),
        ),
      );
      return;
    }

    if (text.trim().isEmpty) return;

    final message = MessageEntity(
      content: text.trim(),
      senderID: cu.userID,
      username: cu.username,
      profileImageUrl: cu.profileImageUrl,
      createdAt: DateTime.now(),
    );

    try {
      // eventID boş olmasın diye kontrol
      if (widget.eventID.isEmpty) {
        throw Exception('Geçersiz eventID');
      }
      await _chatRepository.sendMessage(widget.eventID, message);
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      debugPrint('Chat send error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mesaj gönderilemedi. Lütfen tekrar deneyin.'),
        ),
      );
    }
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
            final uid = (u is Map)
                ? (u['userID'] as String?) ?? ''
                : (u.userID as String? ?? '');
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
    // Auth durumunu beklemek ve uid'nin kesin olmasını sağlamak için authStateChanges kullanıyoruz.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        // waiting aşamasında yükleme gösterebilirsiniz
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final firebaseUser = authSnap.data;
        if (firebaseUser == null) {
          // Giriş yoksa kullanıcıya bilgilendirme gösterin (veya login sayfasına yönlendirin)
          return const Scaffold(
            body: Center(child: Text('Giriş yapılmamış. Lütfen giriş yapın.')),
          );
        }

        // eventID boşsa hata vermeden kullanıcıya bilgi göster:
        if (widget.eventID.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Sohbet')),
            body: const Center(child: Text('Geçersiz sohbet bilgisi.')),
          );
        }

        final currentUserId = firebaseUser.uid;
        // currentUserEntity'yi güncelle (session service boşsa fallback user bilgisi kullanılabilir)
        currentUserEntity =
            getIt<SessionService>().currentUser ?? currentUserEntity;

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

                        final dateDividerString = _getFormattedDate(
                          message.createdAt,
                        );
                        final timeString = DateFormat(
                          'HH:mm',
                        ).format(message.createdAt);

                        String? username;
                        String? avatarUrl;

                        if (!isMe) {
                          username = message.username;
                          avatarUrl = message.profileImageUrl;
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
                              userAvatarUrl: avatarUrl,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              // Input
              ChatInputBar(
                onSend: (text) => _handleSendMessage(text),
              ),
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

    if (dateToCheck == today) {
      return 'Bugün';
    } else if (dateToCheck == yesterday) {
      return 'Dün';
    } else {
      return DateFormat('d MMMM yyyy', 'tr_TR').format(date);
    }
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
