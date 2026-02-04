import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';

typedef OnTimeRangeChanged = void Function(DateTimeRange range);

class MapTimeFilter extends StatefulWidget {
  const MapTimeFilter({super.key, required this.onChanged});
  final OnTimeRangeChanged onChanged;

  @override
  State<MapTimeFilter> createState() => _MapTimeFilterState();
}

class _MapTimeFilterState extends State<MapTimeFilter> {
  double _sliderValue = 0.0;
  final DateTime _today = DateTime.now();

  DateTime get _selectedDate =>
      _today.add(Duration(days: (_sliderValue * 30).round()));

  @override
  Widget build(BuildContext context) {
    final startDate = _selectedDate;
    // zaman aralığı
    final endDate = startDate.add(const Duration(days: 6));

    final dateLabel =
        "${DateFormat('d').format(startDate)}-${DateFormat('d MMM', 'tr_TR').format(endDate)}";

    return Container(
      width: 257.w,
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: const Color(0xFFC6D0D9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: 16.sp,
            color: AppColors.tertiaryColor,
          ),
          SizedBox(width: 6.w),
          Text(
            dateLabel,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.tertiaryColor,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 140.w,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4.h,
                activeTrackColor: AppColors.tertiaryColor,
                inactiveTrackColor: const Color(0xFFDCEAF7),
                thumbColor: AppColors.tertiaryColor,
                trackShape: const RoundedRectSliderTrackShape(),
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: 6.r,
                  elevation: 2,
                ),
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: _sliderValue,
                onChanged: (val) {
                  setState(() => _sliderValue = val);
                  widget.onChanged(
                    DateTimeRange(start: startDate, end: endDate),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
