import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart'; // context.push için
import 'package:permission_handler/permission_handler.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';

class DevicePermissionsPage extends StatefulWidget {
  const DevicePermissionsPage({
    required this.title,
    required this.description,
    required this.permission,
    super.key,
  });

  final String title;
  final String description;
  final Permission permission;

  @override
  State<DevicePermissionsPage> createState() => _DevicePermissionsPageState();
}

class _DevicePermissionsPageState extends State<DevicePermissionsPage>
    with WidgetsBindingObserver {
  bool _isGranted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Sayfa ilk açıldığında durum tespiti
  Future<void> _initialCheck() async {
    final status = await widget.permission.status;
    if (mounted) {
      setState(() {
        _isGranted =
            status.isGranted || status.isLimited || status.isProvisional;
      });
    }
  }

  // Uygulama ön plana çıktığında (Ayarlardan veya Router'dan dönünce)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleResume();
    }
  }

  Future<void> _handleResume() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    // İşletim sistemi ve Router geçişleri için bekleme süresi
    await Future.delayed(const Duration(milliseconds: 500));

    // Polling: 3 kez kontrol et (OS izni geç güncellerse diye)
    for (int i = 0; i < 3; i++) {
      final status = await widget.permission.status;
      final currentStatus =
          status.isGranted || status.isLimited || status.isProvisional;

      if (mounted) {
        setState(() => _isGranted = currentStatus);
      }

      if (currentStatus) break; // İzin verildiyse döngüden çık
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePermission(bool newValue) async {
    if (newValue) {
      // Mevcut durumu kontrol et
      final status = await widget.permission.status;

      // Eğer daha önce reddedilmişse (normal veya kalıcı), direkt ayarlara gönder
      if (status.isDenied || status.isPermanentlyDenied) {
        await openAppSettings();
        return;
      }

      // İlk kez isteniyorsa veya başka bir durumsa sistem popup'ını aç
      final result = await widget.permission.request();

      if (mounted) {
        setState(() {
          _isGranted =
              result.isGranted || result.isLimited || result.isProvisional;
        });

        // Eğer kullanıcı popup'tan reddettiyse ve biz ayarlara gitsin istiyorsak:
        if (!result.isGranted && !result.isLimited) {
          await openAppSettings();
        }
      }
    } else {
      // İzni kapatmak için sistem ayarlarına yönlendir (Uygulama içinden kapatılamaz)
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: _buildAppBar(),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 27.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onBackgroundColor,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch.adaptive(
                        value: _isGranted,
                        activeColor: Colors.white,
                        activeTrackColor: AppColors.primaryColor,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: AppColors.dividerColor,
                        onChanged: _togglePermission,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  widget.description,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textGrey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Siyah ekran yerine yarı şeffaf Loading Overlay
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
      ],
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
        'Cihaz İzinleri',
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
