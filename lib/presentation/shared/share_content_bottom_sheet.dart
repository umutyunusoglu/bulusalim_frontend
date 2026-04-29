import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ShareContentBottomSheet extends StatelessWidget {
  const ShareContentBottomSheet({
    super.key,
    required this.title,
    required this.shareUrl,
    required this.onSharePressed,
    required this.onInstagramSharePressed,
    this.subtitle,
    this.avatarImageUrl,
    this.previewImageUrl,
    this.shareButtonLabel = 'Bağlantıyı Paylaş',
    this.instagramButtonLabel = 'Instagram Hikayede Paylaş',
    this.copySuccessMessage = 'Bağlantı kopyalandı!',
    this.showScannerButton = false,
    this.onScannerPressed,
    this.scannerButtonLabel = 'QR Okut',
  });

  final String title;
  final String? subtitle;
  final String? avatarImageUrl;
  final String? previewImageUrl;
  final String shareUrl;
  final String shareButtonLabel;
  final String instagramButtonLabel;
  final String copySuccessMessage;
  final bool showScannerButton;
  final String scannerButtonLabel;
  final VoidCallback? onScannerPressed;
  final VoidCallback onSharePressed;
  final Future<void> Function(Uint8List? stickerImageBytes)
      onInstagramSharePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 18.h),
            decoration: BoxDecoration(
              color: AppColors.textGrey,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 16.r,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _buildAvatarImage(),
                child: avatarImageUrl == null || avatarImageUrl!.isEmpty
                    ? Icon(Icons.person, size: 20.sp, color: Colors.grey)
                    : null,
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.tertiaryColor,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            SizedBox(height: 6.h),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textGrey,
              ),
            ),
          ],
          SizedBox(height: 18.h),
          if (previewImageUrl != null && previewImageUrl!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              height: 180.h,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                color: AppColors.cardBackgroundColor,
              ),
              child: _buildPreviewImage(),
            ),
            SizedBox(height: 18.h),
          ],
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: const Color(0xFFC6D0D9), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: shareUrl,
              size: 150.w,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.tertiaryColor,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.tertiaryColor,
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.cardBackgroundColor,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                Icon(
                  Symbols.link_2,
                  size: 20.sp,
                  color: AppColors.secondaryColor,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    shareUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.tertiaryColor,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                GestureDetector(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: shareUrl));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            copySuccessMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: AppColors.primaryColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          margin: EdgeInsets.only(
                            bottom: 24.h,
                            left: 40.w,
                            right: 40.w,
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(4.r),
                    color: Colors.transparent,
                    child: Icon(
                      Symbols.content_copy,
                      size: 20.sp,
                      color: AppColors.secondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            height: 40.h,
            child: ElevatedButton.icon(
              onPressed: () async {
                Uint8List? bytes;
                final preview = previewImageUrl;
                if (preview != null && preview.isNotEmpty && preview.startsWith('http')) {
                  try {
                    final uri = Uri.parse(preview);
                    final bundle = NetworkAssetBundle(uri);
                    final data = await bundle.load(preview);
                    bytes = data.buffer.asUint8List();
                  } catch (_) {
                    bytes = null;
                  }
                }

                Navigator.pop(context);
                await onInstagramSharePressed(bytes);
              },
              icon: Icon(
                Symbols.photo_library,
                size: 24.sp,
                color: Colors.white,
              ),
              label: Text(
                instagramButtonLabel,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE1306C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                elevation: 0,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            height: 40.h,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onSharePressed();
              },
              icon: Icon(Symbols.ios_share, size: 24.sp, color: Colors.white),
              label: Text(
                shareButtonLabel,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                elevation: 0,
              ),
            ),
          ),
          if (showScannerButton && onScannerPressed != null) ...[
            SizedBox(height: 12.h),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onScannerPressed!();
              },
              icon: Icon(
                Symbols.qr_code_scanner,
                size: 24.sp,
                color: AppColors.tertiaryColor,
              ),
              label: Text(
                scannerButtonLabel,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.tertiaryColor,
                ),
              ),
            ),
          ],
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  ImageProvider? _buildAvatarImage() {
    final url = avatarImageUrl;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) {
      return CachedNetworkImageProvider(url);
    }
    return AssetImage(url);
  }

  Widget _buildPreviewImage() {
    final url = previewImageUrl!;
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, _) => Container(
          color: AppColors.cardBackgroundColor,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, _, __) => Container(
          color: AppColors.cardBackgroundColor,
          alignment: Alignment.center,
          child: Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.textGrey,
            size: 36.sp,
          ),
        ),
      );
    }

    return Image.asset(url, fit: BoxFit.cover);
  }
}