import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/types/enums/account_type_enum.dart';
import 'package:url_launcher/url_launcher.dart';

class ChangeAccountTypePage extends StatefulWidget {
  const ChangeAccountTypePage({required this.currentType, super.key});
  final String currentType;

  @override
  State<ChangeAccountTypePage> createState() => _ChangeAccountTypePageState();
}

class _ChangeAccountTypePageState extends State<ChangeAccountTypePage> {
  late AccountType _selectedType;

  @override
  void initState() {
    super.initState();
    // Gelen veriye göre başlangıç durumunu belirle
    _selectedType = widget.currentType == 'Topluluk Hesabı'
        ? AccountType.community
        : AccountType.personal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- KİŞİSEL HESAP SEÇENEĞİ ---
            _buildOptionRow(
              title: 'Kişisel Hesap',
              isSelected: _selectedType == AccountType.personal,
              onTap: () {
                setState(() {
                  _selectedType = AccountType.personal;
                });
              },
            ),

            SizedBox(height: 32.h),

            // --- TOPLULUK HESABI SEÇENEĞİ ---
            _buildOptionRow(
              title: 'Topluluk Hesabı',
              isSelected: _selectedType == AccountType.community,
              onTap: () {
                setState(() {
                  _selectedType = AccountType.community;
                });
              },
            ),

            SizedBox(height: 8.h),
            Text(
              'Üniversite toplulukları ve öğrenci kulüpleri için tasarlanmıştır. Topluluk hesabına geçtiğinde, üniversiteye bağlı bir topluluk profili oluşturabilir ve topluluğuna özel özellikleri kullanabilirsin. Topluluk hesabı sahibi olmak için aşağıdaki formu doldur ve seninle iletişime geçelim.',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 11.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textGrey,
                height: 1.4,
              ),
            ),

            // --- KOŞULLU GÖSTERİM ---
            if (_selectedType == AccountType.community) ...[
              SizedBox(height: 16.h),
              GestureDetector(
                onTap: () async {
                  const url = 'https://outnest.app/communities';
                  final uri = Uri.parse(url);

                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    debugPrint('Link açılamadı: $url');
                  }
                },
                child: Text(
                  'Web sitemizdeki Topluluk sayfasını ziyaret et ve bizimle iletişime geç.\nOutnest.app/Communities',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.tertiaryColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
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
        'Hesap Türü',
        style: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.onBackgroundColor,
        ),
      ),
      centerTitle: true,
    );
  }

  // SEÇİM SATIRI WIDGET
  Widget _buildOptionRow({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Başlık
          Text(
            title,
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.onBackgroundColor,
            ),
          ),

          // Özel Radio Butonu
          Container(
            width: 24.w,
            height: 24.w,
            padding: EdgeInsets.all(4.w), // Dış halka ile iç daire arası boşluk
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE5E7EB),
            ),
            child: isSelected
                ? Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryColor,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
