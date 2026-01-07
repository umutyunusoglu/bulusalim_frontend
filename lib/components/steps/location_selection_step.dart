import 'package:bulusalim/components/popup_next_button.dart';
import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LocationSelectionStep extends StatefulWidget {
  const LocationSelectionStep({
    required this.onBack,
    required this.onNext,
    this.initialLocation,
    this.onClose,
    this.onHeaderTap,
    super.key,
  });

  final VoidCallback onBack;
  final ValueChanged<String> onNext;
  final String? initialLocation;
  final VoidCallback? onClose;
  final VoidCallback? onHeaderTap;

  @override
  State<LocationSelectionStep> createState() => _LocationSelectionStepState();
}

class _LocationSelectionStepState extends State<LocationSelectionStep> {
  late TextEditingController _searchController;
  String? _selectedLocation;

  final List<String> _mockLocations = [
    'Kült Kavaklıdere Barbaros, Tunalı Hilmi Cd. No:105',
    'Kuğulu Park Çankaya/Ankara',
    'Kurtuluş Parkı, Fidanlık Çankaya/Ankara',
    'Bahçelievler 7. Cadde, Ankara',
  ];

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _searchController = TextEditingController(
      text: widget.initialLocation ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // 1. HEADER (Tıklanabilir - Picking Mode için)
        GestureDetector(
          onTap: widget.onHeaderTap,
          behavior: HitTestBehavior.opaque,
          child: _buildHeader(theme),
        ),

        SizedBox(height: 20.h),

        // 2. ARAMA VE LİSTE ALANI
        SizedBox(
          height: 260.h,
          child: Column(
            children: [
              Container(
                height: 46.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14.sp,
                    color: AppColors.onBackgroundColor,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Konum ara...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14.sp,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.secondaryColor.withOpacity(0.6),
                      size: 22.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  onChanged: (val) => setState(() => _selectedLocation = val),
                ),
              ),

              SizedBox(height: 12.h),

              // B. Liste Alanı (Gri Arka Planlı)
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA), // Çok açık gri zemin
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(
                      vertical: 12.h,
                      horizontal: 12.w,
                    ),
                    itemCount: _mockLocations.length,
                    separatorBuilder: (_, __) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Divider(height: 1, color: Colors.grey.shade200),
                    ),
                    itemBuilder: (context, index) {
                      final location = _mockLocations[index];
                      final isSelected = _selectedLocation == location;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedLocation = location;
                            _searchController.text = location;
                          });
                        },
                        borderRadius: BorderRadius.circular(8.r),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Konum İkonu (Yuvarlak arka planlı)
                            Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.secondaryColor.withOpacity(0.1)
                                    : Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_on_outlined,
                                size: 16.sp,
                                color: isSelected
                                    ? AppColors.onBackgroundColor
                                    : Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(width: 10.w),

                            // Konum Metni
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top: 2.h,
                                ),
                                child: Text(
                                  location,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 13.sp,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? AppColors.onBackgroundColor
                                        : AppColors.onBackgroundColor
                                              .withOpacity(0.7),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        PopupNextButton(
          text: 'ilerle',
          onPressed: (_selectedLocation == null || _selectedLocation!.isEmpty)
              ? null
              : () => widget.onNext(_selectedLocation!),
        ),

        SizedBox(height: 12.h),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: widget.onBack,
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.undo, size: 22.sp, color: AppColors.iconColor),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 22.sp,
              color: AppColors.iconColor,
            ),
            SizedBox(width: 6.w),
            Text(
              'Buluşma Konumu',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.onBackgroundColor,
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: widget.onClose ?? () {},
            child: Container(
              padding: EdgeInsets.all(8.w),
              child: Icon(Icons.close, size: 22.sp, color: AppColors.iconColor),
            ),
          ),
        ),
      ],
    );
  }
}
