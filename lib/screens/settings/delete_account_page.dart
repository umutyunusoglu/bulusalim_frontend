import 'package:cached_network_image/cached_network_image.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  String? _selectedReason;

  final List<String> _reasons = [
    'Uygulamadan memnun kalmadım',
    'Uygulamayı kullanmıyorum',
    'Gizlilik endişesi',
    'Teknik sorunlar',
    'Diğer',
  ];

  @override
  Widget build(BuildContext context) {
    final currentUser = getIt<SessionService>().currentUser;
    final profileImageUrl = currentUser?.profileImageUrl ?? '';
    final username = currentUser?.username != null
        ? '@${currentUser!.username}'
        : '@kullanici';
    final bool hasUrl =
        profileImageUrl.isNotEmpty && profileImageUrl.startsWith('http');
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            SizedBox(height: 24.h),

            // Başlık
            Text(
              'Hesabınızı kalıcı olarak silmek istediğinize emin misiniz?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.onBackgroundColor,
              ),
            ),

            SizedBox(height: 16.h),

            // Alt Açıklama
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Text(
                'Hesabını sildiğinde, Outnest’teki tüm verilerin kalıcı olarak silinir ve bu işlem geri alınamaz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textGrey,
                  height: 1.4,
                ),
              ),
            ),

            SizedBox(height: 28.h),

            // Profil Alanı (Avatar + Username)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: AppColors.dividerColor,
                  // URL varsa CachedNetworkImageProvider, yoksa senin varsayılan asset resmin
                  backgroundImage: hasUrl
                      ? CachedNetworkImageProvider(
                          fixEmulatorUrl(profileImageUrl),
                        )
                      : AssetImage(FileService.defaultProfileImageUrl())
                            as ImageProvider,
                  onBackgroundImageError: (_, __) =>
                      debugPrint('Avatar Load Error'),
                  // Child artık null, çünkü boşsa ikon yerine direkt asset resmini gösteriyoruz
                  child: null,
                ),
                SizedBox(width: 8.w),
                Text(
                  username,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.onBackgroundColor,
                  ),
                ),
              ],
            ),

            SizedBox(height: 52.h),

            // Dropdown Üstü Mavi Yazı
            Align(
              child: Text(
                'İstersen neden ayrıldığını bizimle paylaşabilirsin.',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.tertiaryColor,
                ),
              ),
            ),

            SizedBox(height: 12.h),

            // Dropdown Kutusu
            Container(
              padding: EdgeInsets.only(left: 16.w, right: 8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F5),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReason,
                  hint: Text(
                    'Seçiniz',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textGrey.withOpacity(0.5),
                    ),
                  ),
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textGrey,
                  ),
                  dropdownColor: const Color(0xFFF1F1F5),
                  elevation: 1,
                  borderRadius: BorderRadius.circular(16.r),
                  items: _reasons.map((String reason) {
                    return DropdownMenuItem<String>(
                      value: reason,
                      child: Text(
                        reason,
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 12.sp,
                          color: const Color(0xFF6C6C80),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedReason = newValue;
                    });
                  },
                ),
              ),
            ),

            SizedBox(height: 215.h),

            // Şifre Uyarısı
            Text(
              'Bu işlemi onaylamak için şifreni girmen gerekiyor.',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textGrey,
              ),
            ),

            SizedBox(height: 16.h),

            // Kırmızı/Turuncu Silme Butonu
            SizedBox(
              width: 173.w,
              height: 40.h,
              child: ElevatedButton(
                onPressed: () {
                  final UserRepository userRepository = getIt<UserRepository>()
                    ..deleteUser(
                      _selectedReason,
                    );

                  //TODO: Ana ekrana dönüp oturumu kapat
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                ),
                child: Text(
                  'hesabı sil',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.iconColor,
          size: 20.sp,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Hesabı Sil',
        style: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.onBackgroundColor,
        ),
      ),
      centerTitle: true,
    );
  }
}
