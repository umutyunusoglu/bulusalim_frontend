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
  int _currentIndex = 11;
  final DateTime _now = DateTime.now();

  List<TimeStep> get _steps {
    final steps = <TimeStep>[
      TimeStep(
        'Başladı',
        DateTimeRange(start: _now, end: _now.add(const Duration(hours: 1))),
      ),
      TimeStep(
        '1 saat İçinde',
        DateTimeRange(start: _now, end: _now.add(const Duration(hours: 1))),
      ),
      TimeStep(
        '2 saat içinde',
        DateTimeRange(start: _now, end: _now.add(const Duration(hours: 2))),
      ),
      TimeStep(
        '6 saat içinde',
        DateTimeRange(start: _now, end: _now.add(const Duration(hours: 6))),
      ),
      TimeStep(
        '12 saat içinde',
        DateTimeRange(start: _now, end: _now.add(const Duration(hours: 12))),
      ),
    ]
    // Saatlik dilimler
    ;

    // Günlük aralıklar (x - x+1, x - x+2 ... x - x+7)
    for (var i = 1; i <= 7; i++) {
      final startDate = DateTime(_now.year, _now.month, _now.day);
      final endDate = startDate.add(
        Duration(days: i, hours: 23, minutes: 59, seconds: 59),
      );

      final label =
          "${DateFormat('d MMM', "tr_TR").format(startDate)} - ${DateFormat('d MMM', "tr_TR").format(endDate)}";
      steps.add(TimeStep(label, DateTimeRange(start: startDate, end: endDate)));
    }

    return steps;
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final currentStep = steps[_currentIndex];

    return Container(
      width: 280.w, // Etiketler uzayabileceği için genişliği biraz artırdım
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: AppColors.inputFillColor,
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
          Icon(Icons.access_time, size: 16.sp, color: AppColors.tertiaryColor),
          SizedBox(width: 6.w),
          Expanded(
            // Yazının sığması için Expanded ekledik
            child: Text(
              currentStep.label,
              style: TextStyle(
                fontSize: 11.sp, // Biraz küçülttük uzun tarihler için
                fontWeight: FontWeight.w500,
                color: AppColors.tertiaryColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 120.w,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4.h,
                activeTrackColor: AppColors.tertiaryColor,
                inactiveTrackColor: const Color(0xFFDCEAF7),
                thumbColor: AppColors.tertiaryColor,
                overlayShape: SliderComponentShape.noOverlay,
                // Durak noktalarını (ticks) göstermek istersen burayı aktif edebilirsin
                tickMarkShape: SliderTickMarkShape.noTickMark,
              ),
              child: Slider(
                value: _currentIndex.toDouble(),
                max: (steps.length - 1).toDouble(),
                divisions: steps.length - 1, // Kesikli geçiş sağlar
                onChanged: (val) {
                  setState(() => _currentIndex = val.round());
                  widget.onChanged(steps[_currentIndex].range);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimeStep {
  TimeStep(this.label, this.range);
  final String label;
  final DateTimeRange range;
}
