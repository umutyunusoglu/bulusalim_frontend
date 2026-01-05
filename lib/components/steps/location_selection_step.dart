import 'package:bulusalim/core/constants/theme/color_themes.dart'; // AppColors Import
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LocationSelectionStep extends StatefulWidget {
  const LocationSelectionStep({
    required this.onBack,
    required this.onNext,
    super.key,
  });

  final VoidCallback onBack;
  final ValueChanged<String> onNext;

  @override
  State<LocationSelectionStep> createState() => _LocationSelectionStepState();
}

class _LocationSelectionStepState extends State<LocationSelectionStep> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedLocation;

  // Mock Data
  final List<String> _mockLocations = [
    "Kült Kavaklıdere Barbaros, Tunalı Hilmi",
    "Kuğulu Park Çankaya/Ankara",
    "Kurtuluş Parkı, Fidanlık Çankaya",
    "Blackfish Cafe, Kızılay",
  ];

  @override
  Widget build(BuildContext context) {
    // Tema verilerine erişim
    final theme = Theme.of(context);

    return Column(
      children: [
        // 1. HEADER
        Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: widget.onBack,
                child: Icon(
                  Icons.undo,
                  size: 24.sp,
                  color: AppColors.iconColor,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 24.sp,
                  color: AppColors.iconColor,
                ),
                SizedBox(width: 4.w),
                Text(
                  "Buluşma Konumu",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onBackgroundColor,
                  ),
                ),
              ],
            ),
          ],
        ),

        SizedBox(height: 24.h),

        // 2. SEARCH BAR
        Container(
          height: 48.h,
          decoration: BoxDecoration(
            color: AppColors.inputFillColor,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: TextField(
            controller: _searchController,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14.sp,
              color: AppColors.onBackgroundColor,
            ),
            decoration: InputDecoration(
              hintText: "Konum ara...",
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.secondaryColor.withOpacity(0.5),
                fontSize: 14.sp,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey,
                size: 20.sp,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14.h),
            ),
            onChanged: (val) {
              setState(() {});
            },
          ),
        ),

        SizedBox(height: 16.h),

        // 3. LİSTE
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: _mockLocations.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: AppColors.dividerColor,
            ),
            itemBuilder: (context, index) {
              final location = _mockLocations[index];
              final isSelected = _selectedLocation == location;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  location,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    // Seçiliyse tam siyah, değilse biraz opak
                    color: isSelected
                        ? AppColors.onBackgroundColor
                        : AppColors.onBackgroundColor.withOpacity(0.8),
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selectedLocation = location;
                    _searchController.text = location;
                  });
                  FocusScope.of(context).unfocus();
                },
              );
            },
          ),
        ),

        SizedBox(height: 16.h),

        // 4. BUTTON
        SizedBox(
          width: 173.w,
          height: 40.h,
          child: ElevatedButton(
            onPressed: _selectedLocation == null
                ? null
                : () {
                    widget.onNext(_selectedLocation!);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.popupBtnBackground,
              foregroundColor: AppColors.popupBtnText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
              disabledBackgroundColor: Colors.grey[200],
              disabledForegroundColor: Colors.grey[400],
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: const Text("İlerle"),
          ),
        ),
      ],
    );
  }
}
