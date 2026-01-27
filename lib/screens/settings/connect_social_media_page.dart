import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ConnectSocialMediaPage extends StatefulWidget {
  const ConnectSocialMediaPage({super.key});

  @override
  State<ConnectSocialMediaPage> createState() => _ConnectSocialMediaPageState();
}

class _ConnectSocialMediaPageState extends State<ConnectSocialMediaPage> {
  String? _xHandle; // Bağlı değil (null)
  final String? _instagramHandle = 'instagram.com/elif_dogan'; // Bağlı
  String? _facebookHandle; // Bağlı değil (null)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        child: Column(
          children: [
            // Instagram
            _buildSocialItem(
              platformName: 'Instagram',
              connectedValue: _instagramHandle,
              onTap: () => _handleConnect('Instagram'),
            ),
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
        'Sosyal Medya Hesabını Bağla',
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

  Widget _buildSocialItem({
    required String platformName,
    String? connectedValue,
    required VoidCallback onTap,
  }) {
    final isConnected = connectedValue != null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol Taraf: Platform İsmi
          Text(
            platformName,
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.onBackgroundColor,
            ),
          ),

          // Sağ Taraf: Durum ve Ok
          Row(
            children: [
              if (isConnected)
                // Bağlıysa: Kullanıcı adı
                Text(
                  connectedValue,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textGrey,
                  ),
                )
              else
                Text(
                  'bağla',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.tertiaryColor,
                  ),
                ),

              SizedBox(width: 8.w),

              // Ok İkonu
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.iconColor,
                size: 24.sp,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleConnect(String platform) {
    debugPrint('$platform tıklandı.');
  }
}
