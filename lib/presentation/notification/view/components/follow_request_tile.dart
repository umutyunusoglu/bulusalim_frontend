import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/entities/notification/follow_notification_entity.dart';
import 'package:outnest/domain/entities/user/friend_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/presentation/notification/view/components/follow_action_button.dart';
import 'package:outnest/presentation/profile/view/dialogs/show_unfollow_dialog.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';
import 'package:outnest/presentation/shared/utility/turkish_time_abbrevetations.dart';
import 'package:timeago/timeago.dart' as timeago;

enum FollowStatus { pending, following, sent, none }

class FollowRequestTile extends StatefulWidget {
  const FollowRequestTile({required this.item, super.key});

  final FollowNotificationEntity item;

  @override
  State<FollowRequestTile> createState() => _FollowRequestTileState();
}

class _FollowRequestTileState extends State<FollowRequestTile> {
  final SessionService _sessionService = getIt<SessionService>();
  final UserRepository _userRepository = getIt<UserRepository>();

  FollowStatus? _currentStatus;
  bool _isLoadingInitialStatus = true;
  bool _isTargetPrivate = false;

  @override
  void initState() {
    super.initState();
    _calculateInitialStatus();
  }

  // --- BAŞLANGIÇ DURUMU HESAPLAMA ---
  Future<void> _calculateInitialStatus() async {
    if (!mounted) return;
    final item = widget.item;

    final myFollowers = _sessionService.currentState.followers;
    final myFollowees = _sessionService.currentState.followees ?? [];

    final amIFollowing = myFollowees.any((f) => f.userID == item.userID);
    final isMyFollower = myFollowers.any((f) => f.userID == item.userID);

    final isMyRequestSent = await _userRepository.isFollowRequestPending(
      _sessionService.currentUser!.userID,
      item.userID,
    );

    final targetUser = await _userRepository.getUserPublicData(item.userID);
    final isPrivate = targetUser?.isPrivate ?? false;

    FollowStatus status;

    if (amIFollowing && isMyFollower) {
      status = FollowStatus.following;
    } else if (isMyRequestSent && !amIFollowing) {
      status = FollowStatus.sent;
    } else if (isMyFollower && !amIFollowing && !isMyRequestSent) {
      status = FollowStatus.none;
    } else {
      status = FollowStatus.pending;
    }

    if (mounted) {
      setState(() {
        _currentStatus = status;
        _isTargetPrivate = isPrivate;
        _isLoadingInitialStatus = false;
      });
    }
  }

  // --- ANA BUTON TAP ---
  Future<void> _onMainButtonTap() async {
    if (_currentStatus == FollowStatus.following) {
      _showUnfollowDialog(context);
      return;
    }

    if (_currentStatus == FollowStatus.sent) {
      await _cancelFollowRequest();
      return;
    }

    // Cache'lenmiş private bilgisi kullanılıyor, network bekleme yok
    if (_isTargetPrivate) {
      unawaited(_sendFollowRequest());
    } else {
      unawaited(_performDirectFollow());
    }
  }

  // --- 1. TAKİBİ BIRAKMA (UNFOLLOW) ---
  Future<void> _performUnfollow() async {
    final currentUser = _sessionService.currentUser;
    if (currentUser == null) return;

    final previousStatus = _currentStatus;
    setState(() => _currentStatus = FollowStatus.none);

    try {
      await _userRepository.removeFollowee(
        currentUser.userID,
        widget.item.userID,
      );
      await _userRepository.removeFollower(
        widget.item.userID,
        currentUser.userID,
      );
    } catch (e) {
      setState(() => _currentStatus = previousStatus);
      showErrorPopup(
        context,
        message: 'İşlem başarısız oldu, lütfen tekrar deneyin.',
      );
    }
  }

  // --- 2. DİREKT TAKİP ETME (PUBLIC ACCOUNT) ---
  Future<void> _performDirectFollow() async {
    final currentUser = _sessionService.currentUser;
    if (currentUser == null) return;

    final previousStatus = _currentStatus;
    setState(() => _currentStatus = FollowStatus.following);

    try {
      final me = Follower(
        userID: currentUser.userID,
        username: currentUser.username,
        profileImageUrl: currentUser.profileImageUrl,
        createdAt: DateTime.now(),
      );

      final target = Followee(
        userID: widget.item.userID,
        username: widget.item.username,
        profileImageUrl: widget.item.profileImageUrl,
        createdAt: DateTime.now(),
      );

      await _userRepository.addFollowee(currentUser.userID, target);
      await _userRepository.addFollower(widget.item.userID, me);
    } catch (e) {
      setState(() => _currentStatus = previousStatus);
      showErrorPopup(
        context,
        message: 'İşlem başarısız oldu, lütfen tekrar deneyin.',
      );
    }
  }

  // --- 3. İSTEK GÖNDERME (PRIVATE ACCOUNT) ---
  Future<void> _sendFollowRequest() async {
    final currentUser = _sessionService.currentUser;
    if (currentUser == null) return;

    final previousStatus = _currentStatus;
    setState(() => _currentStatus = FollowStatus.sent);

    try {
      await _userRepository.sendFollowRequest(
        currentUser.userID,
        widget.item.userID,
        false,
      );
    } catch (e) {
      setState(() => _currentStatus = previousStatus);
      showErrorPopup(
        context,
        message: 'İşlem başarısız oldu, lütfen tekrar deneyin.',
      );
    }
  }

  // --- 4. İSTEĞİ GERİ ÇEKME ---
  Future<void> _cancelFollowRequest() async {
    final currentUser = _sessionService.currentUser;
    if (currentUser == null) return;

    final previousStatus = _currentStatus;
    setState(() => _currentStatus = FollowStatus.none);

    try {
      await _userRepository.cancelFollowRequest(
        currentUser.userID,
        widget.item.userID,
      );
    } catch (e) {
      setState(() => _currentStatus = previousStatus);
      showErrorPopup(
        context,
        message: 'İşlem başarısız oldu, lütfen tekrar deneyin.',
      );
    }
  }

  // --- 5. TAKİP İSTEĞİ KABUL ETME ---
  Future<void> _acceptFollowRequest() async {
    final currentUser = _sessionService.currentUser;
    if (currentUser == null) return;

    final previousStatus = _currentStatus;
    setState(() => _currentStatus = FollowStatus.following);

    try {
      final follower = FriendEntity(
        userID: widget.item.userID,
        username: widget.item.username,
        profileImageUrl: widget.item.profileImageUrl,
        createdAt: DateTime.now(),
      );
      await _userRepository.addFollower(currentUser.userID, follower);
    } catch (e) {
      setState(() => _currentStatus = previousStatus);
      showErrorPopup(
        context,
        message: 'İşlem başarısız oldu, lütfen tekrar deneyin.',
      );
    }
  }

  // --- 6. TAKİP İSTEĞİ REDDETME ---
  Future<void> _rejectFollowRequest() async {
    final currentUser = _sessionService.currentUser;
    if (currentUser == null) return;

    final previousStatus = _currentStatus;
    setState(() => _currentStatus = FollowStatus.none);

    try {
      await _userRepository.cancelFollowRequest(
        widget.item.userID,
        currentUser.userID,
      );
    } catch (e) {
      setState(() => _currentStatus = previousStatus);
      showErrorPopup(
        context,
        message: 'İşlem başarısız oldu, lütfen tekrar deneyin.',
      );
    }
  }

  // --- DIALOG ---
  void _showUnfollowDialog(BuildContext context) {
    showUnfollowDialog(
      context,
      username: widget.item.username,
      profileImageUrl: widget.item.profileImageUrl,
      onConfirm: _performUnfollow,
    );
  }

  // --- BUILD ---
  @override
  Widget build(BuildContext context) {
    timeago.setLocaleMessages('tr_short', TurkishTimeAbbrevetations());

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              context.go('/home/profile/${widget.item.userID}');
            },
            child: CircleAvatar(
              radius: 16.r,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  (widget.item.profileImageUrl.isNotEmpty &&
                      widget.item.profileImageUrl.startsWith('http'))
                  ? CachedNetworkImageProvider(
                      fixEmulatorUrl(widget.item.profileImageUrl),
                    )
                  : AssetImage(FileService.defaultProfileImageUrl())
                        as ImageProvider,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 12.sp,
                  color: Colors.black,
                  height: 1.3,
                ),
                children: [
                  TextSpan(
                    text: '${widget.item.username} ',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text: widget.item.message.replaceAll('\n', ' ').trim(),
                    style: const TextStyle(fontWeight: FontWeight.w400),
                  ),
                  TextSpan(
                    text:
                        ' ${timeago.format(widget.item.createdAt, locale: 'tr_short')}',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          FollowActionButton(
            status: _currentStatus,
            isLoading: _isLoadingInitialStatus,
            onMainTap: _onMainButtonTap,
            onAcceptTap: _acceptFollowRequest,
            onRejectTap: _rejectFollowRequest,
          ),
        ],
      ),
    );
  }
}
