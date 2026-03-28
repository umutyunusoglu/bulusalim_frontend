import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/services/session_service.dart';

class AddAuthority extends StatefulWidget {
  const AddAuthority({
    required this.initialSelectedUsers,
    super.key,
  });
  final List<CompactUserEntity> initialSelectedUsers;

  @override
  State<AddAuthority> createState() => _AddAuthorityState();
}

class _AddAuthorityState extends State<AddAuthority> {
  late List<CompactUserEntity> _selectedUsers;
  String _searchQuery = '';
  final SessionService _sessionService = getIt<SessionService>();

  @override
  void initState() {
    super.initState();
    _selectedUsers = List.from(widget.initialSelectedUsers);
  }

  @override
  Widget build(BuildContext context) {
    final members = _sessionService.currentState.followers;
    final filteredUsers = members.where((user) {
      return user.username.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Dialog(
      backgroundColor: AppColors.popupSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Topluluk Yetkilileri’ne eklemek istediğin\nkullanıcıları aratabilirsin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.onBackgroundColor,
              ),
            ),
            SizedBox(height: 20.h),
            TextField(
              cursorColor: AppColors.onBackgroundColor,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'ara...',
                hintStyle: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 15.sp,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textGrey,
                  size: 20.sp,
                ),
                filled: true,
                fillColor: AppColors.inputFillColor,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.r),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.r),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: filteredUsers.map((user) {
                    final isAdded = _selectedUsers.contains(user);
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: _buildDialogUserItem(user: user, isAdded: isAdded),
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.inputFillColor,
                    foregroundColor: AppColors.onBackgroundColor,
                    elevation: 0,
                    fixedSize: Size(77.w, 34.h),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                  child: Text(
                    'vazgeç',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _selectedUsers);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.onPrimaryColor,
                    elevation: 0,
                    fixedSize: Size(77.w, 34.h),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                  child: Text(
                    'bitir',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogUserItem({
    required CompactUserEntity user,
    required bool isAdded,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20.r,
          backgroundColor: AppColors.dividerColor,
          backgroundImage: NetworkImage(user.profileImageUrl),
          onBackgroundImageError: (_, __) =>
              const Icon(Icons.person, color: AppColors.onPrimaryColor),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            user.username,
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.onBackgroundColor,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              if (isAdded) {
                _selectedUsers.remove(user);
              } else {
                _selectedUsers.add(user);
              }
            });
          },
          child: Container(
            width: 24.r,
            height: 24.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAdded ? AppColors.salmonPink : AppColors.successGreen,
            ),
            child: Icon(
              isAdded ? Icons.remove : Icons.add,
              color: AppColors.onPrimaryColor,
              size: 18.sp,
            ),
          ),
        ),
      ],
    );
  }
}
