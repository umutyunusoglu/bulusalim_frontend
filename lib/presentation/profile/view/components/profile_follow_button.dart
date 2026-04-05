import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/presentation/profile/view/components/announcement_button.dart';
import 'package:outnest/presentation/shared/login_button.dart';

class ProfileFollowButton extends StatelessWidget {
  const ProfileFollowButton({
    required this.isCurrentlyFollowing,
    required this.isPrivateAccount,
    required this.hasSentFollowRequest,
    required this.isFollowing,
    required this.onFollowTap,
    required this.onUnfollowTap,
    required this.onSendRequestTap,
    required this.onAnnouncementTap,
    super.key,
  });

  final bool isCurrentlyFollowing;
  final bool isPrivateAccount;
  final bool hasSentFollowRequest;
  final bool isFollowing;
  final VoidCallback onFollowTap;
  final VoidCallback onUnfollowTap;
  final VoidCallback onSendRequestTap;
  final VoidCallback onAnnouncementTap;

  String get _label {
    if (isCurrentlyFollowing) return 'takibi bırak';
    if (isPrivateAccount && hasSentFollowRequest) return 'istek gönderildi';
    return 'takip et';
  }

  Color _backgroundColor(Color primaryColor) {
    if (isCurrentlyFollowing) return const Color(0xFF5D6B82);
    if (isPrivateAccount && hasSentFollowRequest)
      return const Color(0xFFF2F2F7);
    return primaryColor;
  }

  Color get _textColor {
    if (isPrivateAccount && hasSentFollowRequest && !isCurrentlyFollowing) {
      return const Color(0xFF5D6B82);
    }
    return Colors.white;
  }

  void _handleTap() {
    if (isCurrentlyFollowing) {
      onUnfollowTap();
    } else if (isPrivateAccount) {
      onSendRequestTap();
    } else {
      onFollowTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Expanded(
          child: LoginButton(
            label: _label,
            onPress: _handleTap,
            height: 32.h,
            width: 361,
            borderRadius: 20.r,
            backgroundColor: _backgroundColor(primaryColor),
            textColor: _textColor,
            borderColor: Colors.transparent,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isFollowing || !isPrivateAccount) ...[
          SizedBox(width: 8.w),
          AnnouncementButton(onTap: onAnnouncementTap),
        ],
      ],
    );
  }
}
