import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/components/stacked_avatars.dart'; // <-- StackedAvatars EKLENDİ
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/domain/entities/chat/message_entity.dart';
import 'package:bulusalim/domain/repositories/chat_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class ChatPage extends StatefulWidget {
  final String eventID;
  final String chatTitle;
  final List<AvatarInfo> participantAvatars;
  final String location;
  final String participantStatus;
  final String remainingTime;

  const ChatPage({
    required this.eventID,
    required this.chatTitle,
    required this.participantAvatars,
    required this.location,
    required this.participantStatus,
    required this.remainingTime,
    super.key,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatRepository _chatRepository;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _chatRepository = getIt<ChatRepository>();

    _messageController.addListener(() {
      final isComposing = _messageController.text.trim().isNotEmpty;
      if (isComposing != _isComposing) {
        setState(() {
          _isComposing = isComposing;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final message = MessageEntity(
      content: text,
      senderID: currentUserId,
      createdAt: DateTime.now(),
    );

    _chatRepository.sendMessage(widget.eventID as Identifier, message).then((
      _,
    ) {
      _messageController.clear();
      setState(() {
        _isComposing = false;
      });

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
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // 1. ÖZEL HEADER
            _buildCustomHeader(context),

            // 2. MESAJ LİSTESİ
            Expanded(
              child: StreamBuilder<List<MessageEntity>>(
                stream: _chatRepository.getChatMessagesStream(
                  widget.eventID as Identifier,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        "Sohbeti başlat...",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14.sp,
                          fontFamily: 'Urbanist',
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderID == currentUserId;

                      if (message.content.toLowerCase().contains('bildirim') ||
                          message.content.toLowerCase().contains('katıldı')) {
                        return _buildSystemMessage(message.content);
                      }

                      return _buildMessageRow(message, isMe);
                    },
                  );
                },
              ),
            ),

            // 3. INPUT ALANI
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  // --- WIDGETLAR ---

  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Geri Butonu
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(
              Icons.keyboard_backspace,
              color: Colors.blueGrey,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 8.w),

          // Stacked Avatars Kullanımı
          SizedBox(
            height: 40.h,
            child: StackedAvatars(avatarDataList: widget.participantAvatars),
          ),
          SizedBox(width: 10.w),

          // Başlık ve Detaylar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: Colors.black87,
                  ),
                ),
                // Dinamik Veriler
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 12.sp,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        "${widget.location} • ${widget.participantStatus} • ${widget.remainingTime}",
                        style: TextStyle(
                          fontFamily: 'Urbanist',
                          fontSize: 11.sp,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sağdaki İkonlar
          Icon(Icons.share, color: Colors.grey, size: 20.sp),
          SizedBox(width: 12.w),

          // Ayarlar Butonu Navigasyonu
          GestureDetector(
            onTap: () {
              // Ayarlar sayfasına giderken verileri taşıyoruz
              context.push(
                '/chat/room/${widget.eventID}/settings',
                extra: {
                  'title': widget.chatTitle,
                  'avatars': widget.participantAvatars,
                  'location': widget.location,
                  'participants': widget.participantStatus,
                  'time': widget.remainingTime,
                },
              );
            },
            child: Icon(
              Icons.settings_outlined,
              color: Colors.black87,
              size: 24.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(String content) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Center(
        child: Text(
          content,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12.sp,
            fontFamily: 'Urbanist',
          ),
        ),
      ),
    );
  }

  Widget _buildMessageRow(MessageEntity message, bool isMe) {
    final timeString = DateFormat('HH:mm').format(message.createdAt);

    if (isMe) {
      return Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2E8E5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                    bottomLeft: Radius.circular(16.r),
                    bottomRight: Radius.circular(4.r),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      message.content,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14.sp,
                        fontFamily: 'Urbanist',
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      timeString,
                      style: TextStyle(color: Colors.black45, fontSize: 10.sp),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14.r,
              backgroundImage: const NetworkImage('https://picsum.photos/100'),
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4.r),
                        topRight: Radius.circular(16.r),
                        bottomLeft: Radius.circular(16.r),
                        bottomRight: Radius.circular(16.r),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14.sp,
                        fontFamily: 'Urbanist',
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "kullanici",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10.sp,
                          fontFamily: 'Urbanist',
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        timeString,
                        style: TextStyle(color: Colors.grey, fontSize: 10.sp),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 40.w),
          ],
        ),
      );
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEBEBEB),
          borderRadius: BorderRadius.circular(30.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: TextStyle(fontSize: 14.sp, fontFamily: 'Urbanist'),
                decoration: const InputDecoration(
                  hintText: 'Buraya yaz...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                minLines: 1,
                maxLines: 4,
              ),
            ),

            // Animasyonlu İkon Değişimi (Mic <-> Send)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: _isComposing
                  ? GestureDetector(
                      key: const ValueKey('send'),
                      onTap: _sendMessage,
                      child: Padding(
                        padding: EdgeInsets.all(8.w),
                        child: CircleAvatar(
                          radius: 18.r,
                          backgroundColor: const Color(0xFFFF5722), // Turuncu
                          child: Icon(
                            Icons.arrow_upward,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ),
                      ),
                    )
                  : GestureDetector(
                      key: const ValueKey('mic'),
                      onTap: () {
                        // Sesli mesaj mantığı buraya
                      },
                      child: Padding(
                        padding: EdgeInsets.all(8.w),
                        child: Icon(
                          Icons.mic,
                          color: Colors.blueGrey,
                          size: 24.sp,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
