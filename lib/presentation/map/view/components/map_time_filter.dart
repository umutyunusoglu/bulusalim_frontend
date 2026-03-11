import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';

typedef OnTimeRangeChanged = void Function(DateTimeRange range);

class MapTimeFilter extends StatefulWidget {
  const MapTimeFilter({required this.onChanged, super.key});
  final OnTimeRangeChanged onChanged;

  @override
  State<MapTimeFilter> createState() => _MapTimeFilterState();
}

class _MapTimeFilterState extends State<MapTimeFilter> {
  int _currentIndex = 0; // Varsayılan olarak ilk seçenek (Başladı)
  final DateTime _now = DateTime.now();

  // Tasarımı Slider'dan yatay bir listeye (Chip yapısına) çeviriyoruz
  List<TimeStep> get _steps {
    final steps = <TimeStep>[
      TimeStep(
        'Şimdi',
        DateTimeRange(start: _now, end: _now.add(const Duration(hours: 1))),
      ),
      TimeStep(
        '1s İçinde',
        DateTimeRange(start: _now, end: _now.add(const Duration(hours: 1))),
      ),
      TimeStep(
        '2s İçinde',
        DateTimeRange(start: _now, end: _now.add(const Duration(hours: 2))),
      ),
      TimeStep(
        '6s İçinde',
        DateTimeRange(start: _now, end: _now.add(const Duration(hours: 6))),
      ),
    ];

    // Günlük aralıkları ekle (Görseldeki gibi 7 gün)
    for (var i = 1; i <= 7; i++) {
      final startDate = DateTime(
        _now.year,
        _now.month,
        _now.day,
      ).add(Duration(days: i));
      final endDate = startDate.add(const Duration(hours: 23, minutes: 59));

      final label = DateFormat('d MMM', "tr_TR").format(startDate);
      steps.add(TimeStep(label, DateTimeRange(start: startDate, end: endDate)));
    }
    return steps;
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;

    return Container(
      height: 55.h, // Yüksekliği chip'lere uygun hale getirdik
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        itemCount: steps.length,
        separatorBuilder: (context, index) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final step = steps[index];
          final bool isSelected = _currentIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() => _currentIndex = index);
              widget.onChanged(step.range);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.tertiaryColor
                    : const Color(0xFFF3F5F7),
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(
                  color: isSelected
                      ? AppColors.tertiaryColor
                      : const Color(0xFFC6D0D9).withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.tertiaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                step.label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : AppColors.tertiaryColor.withOpacity(0.7),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TimeStep {
  TimeStep(this.label, this.range);
  final String label;
  final DateTimeRange range;
}
