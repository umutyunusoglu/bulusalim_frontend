import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/entities/user/index.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/domain/usecases/upload_community_picture_usecase.dart';
import 'package:outnest/presentation/settings/view/components/add_authority.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';

class AboutCommunityPage extends StatefulWidget {
  const AboutCommunityPage({super.key});

  @override
  State<AboutCommunityPage> createState() => _AboutCommunityPageState();
}

class _AboutCommunityPageState extends State<AboutCommunityPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _bioController = TextEditingController();
  final SessionService _sessionService = getIt<SessionService>();
  final UploadCommunityPicture _uploadCommunityPicture =
      getIt<UploadCommunityPicture>();

  final UserRepository _userRepository = getIt<UserRepository>();

  File? _selectedImage;
  String? _showDeleteOverlayForId;
  late List<CompactUserEntity> _selectedAuthorities;
  late String? _imagePath = '';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedAuthorities =
        _sessionService.currentUser!.communityData?.communityTeamMembers ?? [];
    _imagePath =
        _sessionService.currentUser!.communityData?.communityPhotoUrl ?? '';
    _bioController.text =
        _sessionService.currentUser!.communityData?.communityBio ?? '';
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Fotoğraf seçilirken hata oluştu: $e');
    }
  }

  Future<void> _openAddAuthorityDialog() async {
    final result = await showDialog<List<CompactUserEntity>>(
      context: context,
      builder: (context) =>
          AddAuthority(initialSelectedUsers: _selectedAuthorities),
    );

    if (result != null) {
      setState(() {
        _selectedAuthorities
          ..clear()
          ..addAll(result);

        _showDeleteOverlayForId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.iconColor,
            size: 26.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: AppColors.onBackgroundColor,
              size: 22.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'Topluluk Hakkında',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.onBackgroundColor,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: AppColors.iconColor, size: 26.sp),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (_showDeleteOverlayForId != null) {
                setState(() => _showDeleteOverlayForId = null);
              }
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16.w,
                right: 16.w,
                top: 20.h,
                bottom: 120.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 361.w,
                    decoration: BoxDecoration(
                      color: AppColors.dividerColor,
                      borderRadius: BorderRadius.circular(16.r),
                      image: _selectedImage != null
                          ? DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            )
                          : (_imagePath!
                                .isNotEmpty) // Eğer yeni resim seçilmediyse ama veritabanında resim varsa onu göster
                          ? DecorationImage(
                              image: NetworkImage(_imagePath!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: Text(
                          '+ fotoğraf ekle',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Topluluk Hakkında',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textGrey,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    height: 80.h,
                    child: TextField(
                      cursorColor: AppColors.onBackgroundColor,
                      controller: _bioController,
                      maxLength: 500,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.onBackgroundColor,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(
                            color: AppColors.dividerColor,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(
                            color: AppColors.dividerColor,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Topluluk Yetkilileri',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textGrey,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 16.w,
                    runSpacing: 16.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ..._selectedAuthorities.map(
                        (user) => _buildAuthorityAvatar(user),
                      ),
                      GestureDetector(
                        onTap: _openAddAuthorityDialog,
                        child: Container(
                          width: 50.r,
                          height: 50.r,
                          decoration: BoxDecoration(
                            color: AppColors.locationBadgeBackground,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.dividerColor,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.add,
                            color: AppColors.onPrimaryColor,
                            size: 28.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 44.h,
            left: 110.w,
            right: 110.w,
            child: ElevatedButton(
              onPressed: () => _updateCommunityData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.onPrimaryColor,
                elevation: 4,
                shadowColor: AppColors.primaryColor.withOpacity(0.4),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20.h,
                      width: 20.h,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'kaydet',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCommunityData() async {
    if (_isLoading) return; // Zaten yükleniyorsa ikinci tıklamayı engelle

    setState(() => _isLoading = true); // Yüklemeyi başlat

    try {
      // Sadece GÜNCEL bir fotoğraf seçildiyse yükleme işlemini yap
      if (_selectedImage != null) {
        _imagePath = await _uploadCommunityPicture(
          userID: _sessionService.currentUser!.userID,
          filePath: _selectedImage!.path,
        );
      }

      final currentCommunityData = _sessionService.currentUser?.communityData;

      final communityData = currentCommunityData != null
          ? currentCommunityData.copyWith(
              communityBio: _bioController.text,
              communityTeamMembers: List.from(_selectedAuthorities),
              communityPhotoUrl: _imagePath,
            )
          : CommunityData(
              communityBio: _bioController.text,
              communityTeamMembers: List.from(_selectedAuthorities),
              communityPhotoUrl: _imagePath ?? '',
              instagramUrl: '',
              whatsappUrl: '',
              websiteUrl: '',
              contactEmail: '',
            );

      await _userRepository.updateUser(_sessionService.currentUser!.userID, {
        'communityData': communityData?.toMap(),
      });

      if (mounted) {
        showInfoPopup(
          context,
          message: 'Topluluk bilgileri başarıyla güncellendi.',
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showErrorPopup(
          context,
          message:
              'Topluluk bilgileri kaydedilirken bir hata oluştu, lütfen tekrar deneyin.',
        );
      }
      debugPrint('Update Error: $e');
    } finally {
      // Hata olsa da başarılı olsa da yükleme animasyonunu durdur
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildAuthorityAvatar(CompactUserEntity user) {
    final isShowingOverlay = _showDeleteOverlayForId == user.userID;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isShowingOverlay) {
            _selectedAuthorities.remove(user);
            _showDeleteOverlayForId = null;
          } else {
            _showDeleteOverlayForId = user.userID;
          }
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 25.r,
                backgroundColor: AppColors.dividerColor,
                backgroundImage: NetworkImage(user.profileImageUrl),
              ),
              if (isShowingOverlay)
                Container(
                  width: 50.r,
                  height: 50.r,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: AppColors.onPrimaryColor,
                    size: 24.sp,
                  ),
                ),
            ],
          ),
          SizedBox(height: 6.h),
          SizedBox(
            width: 60.w,
            child: Text(
              user.username,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.onBackgroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
