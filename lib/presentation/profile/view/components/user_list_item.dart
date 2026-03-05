import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/entities/user/friend_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/domain/session_state.dart';
import 'package:outnest/presentation/profile/view/profile_page.dart';

class UserListItem extends StatefulWidget {
  final CompactUserEntity user;
  final bool isMe;
  final bool isFollowerList;
  final bool isCurrentUser;
  final bool amIFollowing;

  const UserListItem({
    super.key,
    required this.user,
    required this.isMe,
    required this.isFollowerList,
    this.isCurrentUser = false,
    this.amIFollowing = false,
  });

  @override
  State<UserListItem> createState() => _UserListItemState();
}

class _UserListItemState extends State<UserListItem> {
  bool _isActionLoading = false;

  // --- 1. KENDİ LİSTEMİZDEKİ SİLME İŞLEMLERİ (KESİN ÇÖZÜM) ---
  Future<void> _handleMyListRemoveAction() async {
    final sessionService = getIt<SessionService>();
    final userRepository = getIt<UserRepository>();
    final myUserId = sessionService.currentUser?.userID;

    if (myUserId == null) return;

    setState(() => _isActionLoading = true);

    try {
      if (widget.isFollowerList) {
        //  TAKİPÇİLERİNDEN ÇIKAR
        // 1. Adım: Kendi followers listenden onu sil (Senin tarafın temizlenir)
        await userRepository.removeFollower(myUserId, widget.user.userID);

        // 2. Adım: Onun followee listesinden beni sil (Ondaki "takip ediyor" bilgisi silinir)
        // DİKKAT: Eğer burada hata alıyorsan Azure/Firebase güvenlik kuralların
        // başka bir kullanıcının listesine müdahale etmene izin vermiyor demektir.
        try {
          await userRepository.removeFollowee(widget.user.userID, myUserId);
        } catch (innerError) {
          debugPrint(
            'KARŞI TARAF GÜNCELLENEMEDİ (Yetki Sorunu Olabilir): $innerError',
          );
          // Bu hata gelse bile kendi tarafımızı sildiğimiz için devam ediyoruz.
        }
      } else {
        // --- DURUM: TAKİBİ BIRAK ---
        // 1. Adım: Kendi followee listemden onu sil
        await userRepository.removeFollowee(myUserId, widget.user.userID);

        // 2. Adım: Onun followers listesinden beni sil
        try {
          await userRepository.removeFollower(widget.user.userID, myUserId);
        } catch (innerError) {
          debugPrint(
            "KARŞI TARAFIN TAKİPÇİ LİSTESİ GÜNCELLENEMEDİ: $innerError",
          );
        }
      }

      // Veritabanı işlemleri bitti, yerel state'i (ekranı) tazeleyelim
      await sessionService.refreshSession();
    } catch (e) {
      // Sadece senin tarafındaki ana işlem başarısız olursa buraya düşer
      debugPrint("ANA SİLME İŞLEMİ HATASI: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşlem başarısız: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // --- 2. BAŞKASININ LİSTESİNDE İŞLEMLER (GÜNCELLENDİ) ---
  Future<void> _handleOthersListAction(
    bool isCurrentlyFollowing,
    bool hasSentRequest,
  ) async {
    final sessionService = getIt<SessionService>();
    final userRepository = getIt<UserRepository>();
    final myUser = sessionService.currentUser;
    if (myUser == null) return;

    setState(() => _isActionLoading = true);

    try {
      if (isCurrentlyFollowing) {
        // TAKİBİ BIRAK
        await userRepository.removeFollowee(myUser.userID, widget.user.userID);
        try {
          await userRepository.removeFollower(
            widget.user.userID,
            myUser.userID,
          );
        } catch (e) {
          debugPrint("Karşı tarafın listesi güncellenemedi: $e");
        }
      } else if (hasSentRequest) {
        await userRepository.cancelFollowRequest(
          myUser.userID,
          widget.user.userID,
        );
      } else {
        final isPrivate = widget.user.isPrivate ?? false;
        if (isPrivate) {
          await userRepository.sendFollowRequest(
            myUser.userID,
            widget.user.userID,
            false,
          );
        } else {
          // DOĞRUDAN TAKİP ET
          final me = Follower(
            userID: myUser.userID,
            username: myUser.username,
            profileImageUrl: myUser.profileImageUrl,
            createdAt: DateTime.now(),
          );
          final target = Followee(
            userID: widget.user.userID,
            username: widget.user.username,
            profileImageUrl: widget.user.profileImageUrl,
            createdAt: DateTime.now(),
          );
          await userRepository.addFollowee(myUser.userID, target);
          await userRepository.addFollower(widget.user.userID, me);
        }
      }

      await sessionService.refreshSession();
    } catch (e) {
      debugPrint("İşlem başarısız: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem tamamlanamadı.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // --- POP-UP VE UI (Değişmedi) ---
  void _showConfirmationDialog(
    BuildContext context, {
    required bool isMyList,
    bool isCurrentlyFollowing = false,
    bool hasSentRequest = false,
  }) {
    final isRemoveFollower = isMyList ? widget.isFollowerList : false;
    final title = isRemoveFollower
        ? '${widget.user.username} kullanıcısını takipçilerinizden çıkarmak istediğinize emin misiniz?'
        : '${widget.user.username} kullanıcısını takip etmeyi bırakmak istediğinize emin misiniz?';
    final description = isRemoveFollower
        ? 'Kullanıcılara onları takipçilerinizden çıkardığınıza dair bildirim gitmeyecektir.'
        : 'Bu kullanıcıyı tekrar takip etmek için takip isteği göndermeniz gerekecektir.';
    final confirmText = isRemoveFollower ? 'çıkar' : 'takibi bırak';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14.sp,
                    color: Colors.black,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(
                      text: '${widget.user.username} ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: isRemoveFollower
                          ? 'kullanıcısını takipçilerinizden çıkarmak istediğinize emin misiniz?'
                          : 'kullanıcısını takip etmeyi bırakmak istediğinize emin misiniz?',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 11.sp,
                  color: const Color(0xFF8E8E93),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF2F2F7),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                      ),
                      child: Text(
                        'vazgeç',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (isMyList) {
                          _handleMyListRemoveAction();
                        } else {
                          _handleOthersListAction(
                            isCurrentlyFollowing,
                            hasSentRequest,
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                      ),
                      child: Text(
                        confirmText,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(profileUserID: widget.user.userID),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22.r,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: widget.user.profileImageUrl.isNotEmpty
                  ? CachedNetworkImageProvider(widget.user.profileImageUrl)
                  : AssetImage(FileService.defaultProfileImageUrl()),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.nameSurname ?? widget.user.username,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    "@${widget.user.username}",
                    style: TextStyle(
                      color: const Color(0xFF8E8E93),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            _buildActionButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (widget.isCurrentUser) return const SizedBox.shrink();

    return ValueListenableBuilder<SessionState>(
      valueListenable: getIt<SessionService>().stateListenable,
      builder: (context, state, child) {
        final isCurrentlyFollowing = state.followees.any(
          (f) => f.userID == widget.user.userID,
        );
        final hasSentRequest = false;

        String label;
        Color bgColor;
        Color textColor;

        if (widget.isMe) {
          label = widget.isFollowerList
              ? "takipçilerinden çıkar"
              : "takibi bırak";
          bgColor = const Color(0xFFF2F2F7);
          textColor = AppColors.tertiaryColor;
        } else {
          if (isCurrentlyFollowing) {
            label = "takip ediyorsun";
            bgColor = const Color(0xFFF2F2F7);
            textColor = AppColors.tertiaryColor;
          } else if (hasSentRequest) {
            label = "istek gönderildi";
            bgColor = const Color(0xFFF2F2F7);
            textColor = AppColors.tertiaryColor;
          } else {
            label = "takip et";
            bgColor = AppColors.primaryColor;
            textColor = Colors.white;
          }
        }

        return Container(
          constraints: BoxConstraints(minWidth: 80.w),
          height: 28.h,
          child: TextButton(
            onPressed: _isActionLoading
                ? null
                : () {
                    if (widget.isMe) {
                      _showConfirmationDialog(context, isMyList: true);
                    } else {
                      if (isCurrentlyFollowing) {
                        _showConfirmationDialog(
                          context,
                          isMyList: false,
                          isCurrentlyFollowing: true,
                          hasSentRequest: hasSentRequest,
                        );
                      } else {
                        _handleOthersListAction(
                          isCurrentlyFollowing,
                          hasSentRequest,
                        );
                      }
                    }
                  },
            style: TextButton.styleFrom(
              backgroundColor: bgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
            ),
            child: _isActionLoading
                ? SizedBox(
                    height: 12.h,
                    width: 12.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
