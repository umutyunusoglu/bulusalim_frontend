import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/presentation/map/view/components/community_event_info_card.dart';

class CommunityEventDetailPreviewPage extends StatelessWidget {
  const CommunityEventDetailPreviewPage({
    required this.data,
    super.key,
  });

  final Map<String, dynamic> data;

  File? get _coverImage => data['coverImage'] as File?;
  String get _description => data['description'] as String? ?? '';
  String get _rules => data['rules'] as String? ?? '';
  String get _venueInfo => data['venueInfo'] as String? ?? '';
  String get _link => data['link'] as String? ?? '';
  int get _maxParticipants => data['maxParticipants'] as int? ?? 0;
  String get _eventName => data['eventName'] as String? ?? '';
  String get _displayAddress => data['displayAddress'] as String? ?? '';
  DateTime get _startTime => data['startTime'] as DateTime? ?? DateTime.now();
  String get _category => data['category'] as String? ?? '';
  bool get _requiresDocument => data['requiresDocument'] as bool? ?? false;

  @override
  Widget build(BuildContext context) {
    final session = getIt<SessionService>().currentUser;
    final profileImageUrl = session?.communityData?.communityPhotoUrl ?? '';
    final communityName = session?.nameSurname ?? session?.username ?? '';

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(context, profileImageUrl, communityName),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FOTOĞRAF
                  Center(
                    child: _coverImage != null
                        ? Image.file(
                            _coverImage!,
                            width: 361.w,
                            height: 361.h,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 361.w,
                            height: 361.h,
                            color: AppColors.inputFillColor,
                            child: Icon(
                              Icons.image_outlined,
                              size: 48.sp,
                              color: AppColors.textGrey,
                            ),
                          ),
                  ),

                  // ETKİNLİK BİLGİ KARTI
                  CommunityEventInfoCard(
                    profileImageUrl: profileImageUrl,
                    communityName: communityName,
                    eventName: _eventName,
                    displayAddress: _displayAddress,
                    startTime: _startTime,
                    maxParticipants: _maxParticipants,
                    link: _link.isNotEmpty ? _link : null,
                    category: _category,
                    requiresDocument: _requiresDocument,
                  ),

                  // DETAY BÖLÜMLERİ
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 17.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_description.isNotEmpty) ...[
                          _buildSection('Buluşma Hakkında', _description),
                          SizedBox(height: 16.h),
                        ],
                        if (_rules.isNotEmpty && _rules.trim() != '•') ...[
                          _buildSection(
                            'Katılım Kuralları & Gereklilikler',
                            _rules,
                          ),
                          SizedBox(height: 16.h),
                        ],
                        if (_venueInfo.isNotEmpty) ...[
                          _buildSection('Mekan', _venueInfo),
                          SizedBox(height: 16.h),
                        ],
                        if (_link.isNotEmpty) ...[
                          _buildSection('Bilet Al', _link, isLink: true),
                          SizedBox(height: 16.h),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          _buildBottomButtons(context),
        ],
      ),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    String profileImageUrl,
    String communityName,
  ) => AppBar(
    backgroundColor: AppColors.backgroundColor,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(
        Symbols.reply,
        color: AppColors.onBackgroundColor,
      ),
      onPressed: () => context.pop(),
    ),
    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14.r,
          backgroundColor: AppColors.inputFillColor,
          backgroundImage: profileImageUrl.isNotEmpty
              ? CachedNetworkImageProvider(
                  profileImageUrl,
                )
              : null,
          child: profileImageUrl.isEmpty
              ? Icon(Icons.group, size: 16.sp, color: AppColors.textGrey)
              : null,
        ),
        SizedBox(width: 8.w),
        Text(
          communityName,
          style: TextStyle(
            color: AppColors.onBackgroundColor,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
    centerTitle: true,
  );

  Widget _buildBottomButtons(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              side: const BorderSide(color: AppColors.secondaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
              ),
            ),
            child: Text(
              'düzenle',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.onBackgroundColor,
              ),
            ),
          ),
        ),

        SizedBox(width: 12.w),

        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () => context
              ..pop()
              ..pop(data),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
              ),
            ),
            child: Text(
              'onayla ve ilerle',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.onPrimaryColor,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildSection(
    String title,
    String content, {
    bool isLink = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: AppColors.textGrey,
        ),
      ),
      SizedBox(height: 6.h),
      Text(
        content,
        style: TextStyle(
          fontSize: 13.sp,
          height: 1.6,
          color: isLink ? AppColors.tertiaryColor : AppColors.onBackgroundColor,
        ),
      ),
    ],
  );
}
