import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  Future<void> _initialCheck() async {
    final status = await widget.permission.status;
    if (mounted) {
      setState(() {
        _isGranted =
            status.isGranted || status.isLimited || status.isProvisional;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleResume();
    }
  }

  Future<void> _handleResume() async {
    if (!mounted) return;

    try {
      setState(() => _isLoading = true);

      // İşletim sisteminin ve platform kanallarının toparlanması için kısa bir süre bekle
      await Future.delayed(const Duration(milliseconds: 500));

      final status = await widget.permission.status;
      final currentStatus =
          status.isGranted || status.isLimited || status.isProvisional;

      if (mounted) {
        setState(() {
          _isGranted = currentStatus;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Resume sırasında izin kontrolü hatası: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Ok ikonuna tıklandığında doğrudan ayarlara gönderir
  Future<void> _goToSettings() async {
    await openAppSettings();
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
            child: InkWell(
              // Tüm satırı tıklanabilir yapmak UX açısından daha iyidir
              onTap: _goToSettings,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackgroundColor,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _isGranted ? "İzin Verildi" : "İzin Verilmedi",
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 13.sp,
                              color: _isGranted
                                  ? Colors.green
                                  : AppColors.textGrey,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16.sp,
                            color: _isGranted
                                ? Colors.green
                                : AppColors.textGrey,
                          ),
                        ],
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
        ),
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
