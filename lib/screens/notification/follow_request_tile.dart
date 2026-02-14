import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/domain/entities/notification/follow_notification_entity.dart';
import 'package:outnest/domain/entities/user/friend_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class FollowRequestTile extends StatefulWidget {
  const FollowRequestTile({required this.item, super.key});
  final FollowNotificationEntity item;

  @override
  State<FollowRequestTile> createState() => _FollowRequestTileState();
}

class _FollowRequestTileState extends State<FollowRequestTile> {
  final LoggingService _logger = getIt<LoggingService>();
  late FollowStatus _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.item.status;
  }

  String _resolveAvatarUrl() {
    final raw = (widget.item.profileImageUrl ?? '').trim();
    if (raw.isEmpty || raw.startsWith('gs://')) return '';
    return fixEmulatorUrl(raw);
  }

  Widget _buildButton({
    required String text,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11.sp,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingAction() {
    final userRepository = getIt<UserRepository>();
    final sessionService = getIt<SessionService>();
    final currentUser = sessionService.currentUser;

    switch (_currentStatus) {
      case FollowStatus.following:
        return _buildButton(
          text: 'takip ediliyor',
          bgColor: const Color(0xFFF2F2F7),
          textColor: const Color(0xFF3A3A3C),
          onTap: () {},
        );

      case FollowStatus.sent:
        return _buildButton(
          text: 'istek gönderildi',
          bgColor: const Color(0xFFF2F2F7),
          textColor: const Color(0xFF3A3A3C),
          onTap: () {},
        );

      case FollowStatus.none:
        return _buildButton(
          text: 'takip et',
          bgColor: AppColors.primaryColor,
          textColor: Colors.white,
          onTap: () async {
            // TODO: Takip etme işlemi
            _logger.info('Takip et butonuna tıklandı: ${item.username}');

            final sessionService = getIt<SessionService>();
            final userRepository = getIt<UserRepository>();

            final targetUserID = item.userID;
            final currentUser = sessionService.currentUser;

            final targetUser = await userRepository.getUserPublicData(
              targetUserID,
            );

            if (targetUser?.isPrivate ?? false) {
              // Özel hesap, takip isteği gönder
              _logger.info(
                'Özel hesaba takip isteği gönderiliyor: ${targetUser?.username}',
              );

              if (targetUser?.isPrivate ?? false) {
                // Gizli hesap: İstek gönderildi durumuna geç
                await userRepository.sendFollowRequest(
                  currentUser.userID,
                  widget.item.userID,
                  true,
                );
                if (mounted) setState(() => _currentStatus = FollowStatus.sent);
              } else {
                // Açık hesap: Takip ediliyor durumuna geç
                await userRepository.addFollowee(
                  currentUser.userID,
                  FriendEntity(
                    userID: widget.item.userID,
                    username: widget.item.username ?? '',
                    profileImageUrl: widget.item.profileImageUrl ?? '',
                    createdAt: DateTime.now(),
                  ),
                );
                if (mounted)
                  setState(() => _currentStatus = FollowStatus.following);
              }
            } catch (e) {
              _logger.error('Follow error: $e');
            }
          },
        );

      case FollowStatus.pending:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildButton(
              text: 'kabul et',
              bgColor: AppColors.primaryColor,
              textColor: Colors.white,
              onTap: () async {
                if (currentUser == null) return;
                try {
                  await userRepository.addFollower(
                    currentUser.userID,
                    FriendEntity(
                      userID: widget.item.userID,
                      username: widget.item.username ?? '',
                      profileImageUrl: widget.item.profileImageUrl ?? '',
                      createdAt: DateTime.now(),
                    ),
                  );
                  if (mounted)
                    setState(() => _currentStatus = FollowStatus.following);
                } catch (e) {
                  _logger.error('Accept error: $e');
                }
              },
            ),
            SizedBox(width: 6.w),
            _buildButton(
              text: 'sil',
              bgColor: const Color(0xFFF2F2F7),
              textColor: const Color(0xFF3A3A3C),
              onTap: () async {
                if (currentUser == null) return;
                try {
                  await userRepository.cancelFollowRequest(
                    currentUser.userID,
                    widget.item.userID,
                  );
                  if (mounted)
                    setState(() => _currentStatus = FollowStatus.none);
                } catch (e) {
                  _logger.error('Delete error: $e');
                }
              },
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _resolveAvatarUrl();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 44.r,
            height: 44.r,
            child: ClipOval(
              child: avatarUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Image.asset(
                        'assets/defaults/default_profile.jpg',
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      'assets/defaults/default_profile.jpg',
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 13.sp,
                  color: Colors.black,
                  height: 1.2,
                ),
                children: [
                  TextSpan(
                    text: '${widget.item.username ?? 'Kullanıcı'} ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: (widget.item.message ?? '')
                        .replaceAll('\n', ' ')
                        .trim(),
                    style: const TextStyle(fontWeight: FontWeight.w400),
                  ),
                  TextSpan(
                    text:
                        ' ${timeago.format(widget.item.createdAt, locale: 'tr_short')}',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8.w),
          _buildTrailingAction(),
        ],
      ),
    );
  }
}
