import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// context.pop() için
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/entities/notification/follow_notification_entity.dart';
import 'package:outnest/domain/entities/user/friend_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';
import 'package:timeago/timeago.dart' as timeago;

// Durum Enum'ı
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

  @override
  void initState() {
    super.initState();
    _calculateInitialStatus();
  }

  // --- BAŞLANGIÇ DURUMU HESAPLAMA ---
  Future<void> _calculateInitialStatus() async {
    if (!mounted) return;
    final item = widget.item;

    final myFollowers = _sessionService.currentState?.followers ?? [];
    final myFollowees = _sessionService.currentState?.followees ?? [];

    final amIFollowing = myFollowees.any((f) => f.userID == item.userID);
    final isMyFollower = myFollowers.any((f) => f.userID == item.userID);

    // Senin gönderdiğin bir istek var mı?
    final isMyRequestSent = await _userRepository.isFollowRequestPending(
      _sessionService.currentUser!.userID,
      item.userID,
    );

    FollowStatus status;

    // 1. KURAL: İsteğim kabul edildiyse ve o da beni takip ediyorsa -> Takip Ediliyor
    if (amIFollowing && isMyFollower) {
      status = FollowStatus.following;
    }
    // 2. KURAL: İstek yolladıysam ama henüz kabul edilmediysem -> İstek Yollandı
    else if (isMyRequestSent && !amIFollowing) {
      status = FollowStatus.sent;
    } else if (isMyFollower && !amIFollowing && !isMyRequestSent) {
      status = FollowStatus.none;
    } else {
      status = FollowStatus.pending;
    }

    if (mounted) {
      setState(() {
        _currentStatus = status;
        _isLoadingInitialStatus = false;
      });
    }
  }

  Future<void> _onMainButtonTap() async {
    final targetUserID = widget.item.userID;

    if (_currentStatus == FollowStatus.following) {
      _showUnfollowDialog(context);
      return;
    }

    if (_currentStatus == FollowStatus.sent) {
      await _cancelFollowRequest();
      return;
    }

    // 3. Hiçbiri değilse (Takip Et durumu) -> Gizli mi değil mi kontrol et ve işlem yap
    // Kullanıcının gizlilik durumunu bilmediğimiz için hızlıca çekiyoruz
    final targetUser = await _userRepository.getUserPublicData(targetUserID);
    final isPrivate = targetUser?.isPrivate ?? false;

    if (isPrivate) {
      await _sendFollowRequest();
    } else {
      await _performDirectFollow();
    }
  }

  // --- 1. TAKİBİ BIRAKMA (UNFOLLOW) ---
  Future<void> _performUnfollow() async {
    final currentUser = _sessionService.currentUser;
    if (currentUser == null) return;

    // Optimistic Update: Hemen takibi bırakmış gibi göster
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
      // Not: removeFollowee çağrıldığında SessionService muhtemelen kendini günceller
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

    // Optimistic Update: Hemen takip ediyor gibi göster
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

    // Optimistic Update: İstek gönderildi yap
    final previousStatus = _currentStatus;
    setState(() => _currentStatus = FollowStatus.sent);

    try {
      await _userRepository.sendFollowRequest(
        currentUser.userID,
        widget.item.userID,
        false, // isAccepted başlangıçta false
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

    // Optimistic Update: Takip et butonuna geri dön
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

  // --- DIALOG ---
  void _showUnfollowDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // Popup widget'ınız yoksa AlertDialog kullanın
        title: Text(
          '${widget.item.username} hesabını takip etmeyi bırakmak istediğine emin misin?',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bu hesabı tekrardan takip etmek için istek tekrardan göndermen gerekecek.',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Vazgeç", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF5D6B82),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context); // Dialogu kapat
              _performUnfollow(); // Silme işlemini başlat
            },
            child: const Text("Takibi Bırak"),
          ),
        ],
      ),
    );
  }

  // --- ARAYÜZ (WIDGETS) ---
  Widget _buildActionContent() {
    if (_isLoadingInitialStatus) {
      return SizedBox(
        width: 20.w,
        height: 20.h,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    switch (_currentStatus) {
      case FollowStatus.following:
        return GestureDetector(
          onTap: _onMainButtonTap, // Tıklayınca dialog açar
          child: _buildStatusContainer(
            'takip ediliyor',
            const Color(0xFFF2F2F7),
            AppColors.tertiaryColor,
          ),
        );

      case FollowStatus.sent:
        return GestureDetector(
          onTap: _onMainButtonTap, // Tıklayınca isteği geri çeker
          child: _buildStatusContainer(
            'istek gönderildi',
            const Color(0xFFF2F2F7),
            AppColors.tertiaryColor,
          ),
        );

      case FollowStatus.none:
      case null:
        return GestureDetector(
          onTap: _onMainButtonTap, // Gizli/Açık kontrolü yapıp takip eder
          child: _buildStatusContainer(
            'takip et',
            AppColors.primaryColor,
            Colors.white,
            isElevated: true, // Gölge var
          ),
        );

      case FollowStatus.pending:
        // Bu tile "sana gelen istek" ise (bildirim)
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                // Kabul etme mantığı buraya (basitçe)
                final currentUser = _sessionService.currentUser;
                final follower = FriendEntity(
                  userID: widget.item.userID,
                  username: widget.item.username,
                  profileImageUrl: widget.item.profileImageUrl,
                  createdAt: DateTime.now(),
                );
                await _userRepository.addFollower(
                  currentUser!.userID,
                  follower,
                );
                // Burayı da optimistic yapmak gerekebilir ama şimdilik bırakıyoruz
              },
              child: _buildStatusContainer(
                'kabul et',
                AppColors.primaryColor,
                Colors.white,
                isElevated: true, // Gölge var
              ),
            ),
            SizedBox(width: 4.w),
            GestureDetector(
              onTap: () {
                // Silme/Reddetme mantığı
              },
              child: _buildStatusContainer(
                'sil',
                const Color(0xFFF2F2F7),
                AppColors.tertiaryColor,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildStatusContainer(
    String text,
    Color bgColor,
    Color textColor, {
    bool isElevated = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: isElevated
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ]
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    timeago.setLocaleMessages('tr_short', TrShortMessages());
    // ... (Build metodunun geri kalanı, Avatar ve RichText kısımları aynı)
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          CircleAvatar(
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
          _buildActionContent(),
        ],
      ),
    );
  }
}

// ... TrShortMessages sınıfı aynı
class TrShortMessages implements timeago.LookupMessages {
  // ... (Önceki kod ile aynı)
  @override
  String prefixAgo() => '';
  @override
  String prefixFromNow() => '';
  @override
  String suffixAgo() => '';
  @override
  String suffixFromNow() => '';
  @override
  String lessThanOneMinute(int seconds) => 'şimdi';
  @override
  String aboutAMinute(int minutes) => '1dk';
  @override
  String minutes(int minutes) => '${minutes}dk';
  @override
  String aboutAnHour(int minutes) => '1sa';
  @override
  String hours(int hours) => '${hours}sa';
  @override
  String aDay(int hours) => '1gn';
  @override
  String days(int days) => '${days}gn';
  @override
  String aboutAMonth(int days) => '1ay';
  @override
  String months(int months) => '${months}ay';
  @override
  String aboutAYear(int year) => '1yl';
  @override
  String years(int years) => '${years}yl';
  @override
  String wordSeparator() => ' ';
}
