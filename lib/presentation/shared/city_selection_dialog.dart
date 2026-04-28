import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_identity_provider.dart';
import 'package:outnest/application/data_providers/turkey_cities_provider.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/repositories/user_repository.dart';

class CitySelectionDialog extends HookConsumerWidget {
  const CitySelectionDialog({
    super.key,
    this.isDismissible = false,
  });
  final bool isDismissible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cities = ref.watch(turkeyCitiesProvider);
    final selectedCity = useState<String?>(null);
    final searchQuery = useState<String>('');

    final filteredCities = cities
        .where(
          (city) =>
              city.toLowerCase().contains(searchQuery.value.toLowerCase()),
        )
        .toList();

    return PopScope(
      canPop: isDismissible, // isDismissible true ise Android geri tuşu çalışır
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        backgroundColor: AppColors.popupSurface,
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Container(
          width: 360.w,
          height: 420.h,
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(
                height: 24.h,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Eğer iptal edilebilir ise sola X butonu koy
                    if (isDismissible)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          behavior: HitTestBehavior.opaque,
                          child: Icon(
                            Symbols.close,
                            size: 24.sp,
                            color: AppColors.onBackgroundColor,
                          ),
                        ),
                      ),
                    Text(
                      'Şehri Seç',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onBackgroundColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              Container(
                height: 40.h,
                decoration: BoxDecoration(
                  color: AppColors.inputFillColor,
                  borderRadius: BorderRadius.circular(25.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    Icon(
                      Symbols.search,
                      color: AppColors.textGrey,
                      size: 20.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: TextField(
                        onChanged: (val) => searchQuery.value = val,
                        textAlignVertical: TextAlignVertical.center,
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 14.sp,
                          color: AppColors.onBackgroundColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Şehir ara...',
                          hintStyle: TextStyle(
                            fontFamily: 'SF Pro Display',
                            color: AppColors.textGrey,
                            fontSize: 14.sp,
                          ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),

              // LİSTE
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.popupSurface,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: filteredCities.length,
                    itemBuilder: (context, index) {
                      final city = filteredCities[index];
                      final isSelected = selectedCity.value == city;
                      return ListTile(
                        visualDensity: VisualDensity.compact,
                        title: Text(
                          city,
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 14.sp,
                            color: isSelected
                                ? AppColors.primaryColor
                                : AppColors.onBackgroundColor,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Symbols.check_circle,
                                color: AppColors.primaryColor,
                                size: 20.sp,
                              )
                            : null,
                        onTap: () => selectedCity.value = city,
                      );
                    },
                  ),
                ),
              ),

              SizedBox(height: 12.h),
              Text(
                'Sana en uygun buluşmaları gösterebilmemiz için lütfen bulunduğun şehri doğru gir.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 11.sp,
                  color: AppColors.textGrey,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 16.h),

              // KAYDET BUTONU
              SizedBox(
                width: 116.w,
                height: 34.h,
                child: ElevatedButton(
                  onPressed: selectedCity.value != null
                      ? () async {
                          final userId = ref.read(currentUserIDProvider);
                          if (userId != null) {
                            await getIt<UserRepository>().updateUser(userId, {
                              'city': selectedCity.value,
                            });
                            if (context.mounted) {
                              Navigator.pop(context, selectedCity.value);
                            }
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    disabledBackgroundColor: AppColors.infoBadgeBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Kaydet',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onPrimaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
