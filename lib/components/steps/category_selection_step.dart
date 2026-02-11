import 'package:outnest/components/map_filter_chip.dart';
import 'package:outnest/components/popup_next_button.dart';
import 'package:outnest/core/constants/theme/color_themes.dart'; // AppColors
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CategorySelectionStep extends StatefulWidget {
  const CategorySelectionStep({
    required this.initialSelectedCategory,
    required this.categories,
    required this.onClose,
    required this.onNext,
    super.key,
  });

  final String? initialSelectedCategory;
  final Map<String, String> categories;
  final VoidCallback onClose;
  final ValueChanged<String> onNext;

  @override
  State<CategorySelectionStep> createState() => _CategorySelectionStepState();
}

class _CategorySelectionStepState extends State<CategorySelectionStep> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialSelectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // 1. HEADER
        Stack(
          alignment: Alignment.center,
          children: [
            // SOL BUTON (Geri)
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: widget.onClose,
                child: Icon(
                  Icons.undo,
                  size: 24.sp,
                  color: AppColors.iconColor,
                ),
              ),
            ),

            // ORTA BAŞLIK
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.label_outline,
                  size: 24.sp,
                  color: AppColors.iconColor,
                ),
                SizedBox(width: 4.w),
                Text(
                  'Buluşma Teması',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onBackgroundColor,
                  ),
                ),
              ],
            ),

            // SAĞ BUTON (Kapatma İkonu)
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: widget.onClose,
                child: Icon(
                  Icons.close,
                  size: 24.sp,
                  color: AppColors.iconColor,
                ),
              ),
            ),
          ],
        ),

        // Header ile Liste Arasındaki Boşluk
        SizedBox(height: 24.h),

        // 2. KATEGORİ LİSTESİ
        Wrap(
          spacing: 12.w, // Yatay boşluk
          runSpacing: 12.h, // Dikey boşluk
          alignment: WrapAlignment.center,
          children: widget.categories.entries.map((entry) {
            final categoryName = entry.key;
            final categoryEmoji = entry.value;
            final isSelected = _selectedCategory == categoryName;

            return MapFilterChip(
              label: categoryName.toLowerCase(),
              emoji: categoryEmoji,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedCategory = categoryName;
                });
              },
            );
          }).toList(),
        ),

        // Liste ile Buton arasını doldurur
        const Spacer(),

        // 3. İLERLE BUTONU
        PopupNextButton(
          // Seçim yapılmamışsa buton pasif (null) olur
          onPressed: _selectedCategory == null
              ? null
              : () {
                  widget.onNext(_selectedCategory!);
                },
        ),
      ],
    );
  }
}
