import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

class DevicePermissionsPage extends StatefulWidget {
  const DevicePermissionsPage({
    super.key,
    required this.title,
    required this.description,
    required this.permission,
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Kullanıcı ayarlara gidip geri dönerse durumu güncelle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionStatus();
    }
  }

  Future<void> _checkPermissionStatus() async {
    final status = await widget.permission.status;
    if (mounted) {
      setState(() {
        _isGranted = status.isGranted || status.isLimited;
      });
    }
  }

  Future<void> _togglePermission(bool value) async {
    if (value) {
      // Switch AÇILDI -> İzin İste
      // (Eğer daha önce reddedildiyse popup çıkmayabilir, bu Android/iOS kuralıdır)
      final status = await widget.permission.request();

      if (mounted) {
        setState(() {
          _isGranted = status.isGranted || status.isLimited;
        });
      }

      // Eğer kalıcı olarak reddedildiyse ayarlara yönlendir
      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
    } else {
      // Switch KAPANDI -> Sistem iznini kapatmak için ayarlara gitmek gerekir
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 27.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık ve Switch Satırı
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

            // Açıklama Metni
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

            SizedBox(height: 20.h),

            // Gizlilik Linki
            GestureDetector(
              onTap: () {
                debugPrint('Gizlilik politikasına gidiliyor...');
              },
              child: Text(
                'Gizlilik ve veri kullanımı hakkında daha fazla bilgi al',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.tertiaryColor,
                ),
              ),
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
