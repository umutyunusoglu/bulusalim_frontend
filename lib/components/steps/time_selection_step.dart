import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:outnest/components/popup_next_button.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';

class TimeSelectionStep extends StatefulWidget {
  const TimeSelectionStep({
    required this.onBack,
    required this.onNext,
    this.onClose,
    // YENİ: X butonunu gizlemek için parametre
    this.hideCloseButton = false,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback? onClose;
  final Function(DateTime date, TimeOfDay? time, bool isTimeUndefined) onNext;
  final bool hideCloseButton; // Değişken tanımı

  @override
  State<TimeSelectionStep> createState() => _TimeSelectionStepState();
}

class _TimeSelectionStepState extends State<TimeSelectionStep> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isTimeUndefined = false;

  late DateTime _currentMonth;
  late DateTime _now;
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _currentMonth = DateTime(_now.year, _now.month);

    initializeDateFormatting('tr_TR').then((_) {
      if (mounted) {
        setState(() {
          _localeInitialized = true;
        });
      }
    });
  }

  // --- SAAT SEÇİCİ (CUPERTINO WHEEL) ---
  void _pickTime() {
    final initialDateTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6),
        color: AppColors.popupSurface,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: initialDateTime,
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      _selectedTime = TimeOfDay.fromDateTime(newDate);
                      _isTimeUndefined = false;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isDateSelectable(DateTime date) {
    final diff = date
        .difference(DateTime(_now.year, _now.month, _now.day))
        .inDays;
    return diff >= 0 && diff <= 7;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);
    final daysInMonth = DateUtils.getDaysInMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    final firstDayOffset =
        DateTime(_currentMonth.year, _currentMonth.month).weekday % 7;
    final monthName = DateFormat('MMMM yyyy', 'tr_TR').format(_currentMonth);

    return Column(
      children: [
        // 1. HEADER
        Stack(
          alignment: Alignment.center,
          children: [
            // SOL BUTON (GERİ)
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

            // ORTA BAŞLIK
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 24.sp,
                  color: AppColors.iconColor,
                ),
                SizedBox(width: 4.w),
                Text(
                  'Buluşma Zamanı',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onBackgroundColor,
                  ),
                ),
              ],
            ),

            // SAĞ BUTON (KAPAT) - SADECE hideCloseButton FALSE İSE GÖSTER
            if (!widget.hideCloseButton)
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

        SizedBox(height: 12.h),

        // 2. AY VE YIL
        Text(
          monthName,
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.onBackgroundColor,
          ),
        ),

        SizedBox(height: 10.h),

        // 3. GÜN İSİMLERİ
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['P', 'S', 'Ç', 'P', 'C', 'C', 'P']
                .map(
                  (day) => SizedBox(
                    width: 26.w,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0XFF8E8E93),
                        fontSize: 14.sp,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        SizedBox(height: 4.h),

        // 4. TAKVİM GRİDİ
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 24.w,
              mainAxisSpacing: 6.h,
              childAspectRatio: 0.9,
            ),
            itemCount: daysInMonth + firstDayOffset,
            itemBuilder: (context, index) {
              if (index < firstDayOffset) return const SizedBox.shrink();

              final day = index - firstDayOffset + 1;
              final date = DateTime(
                _currentMonth.year,
                _currentMonth.month,
                day,
              );

              final isSelectable = _isDateSelectable(date);
              final isSelected = _isSameDay(date, _selectedDate);
              final isToday = _isSameDay(date, _now);

              Color textColor;
              if (isSelected) {
                textColor = Colors.white;
              } else if (isToday) {
                textColor = AppColors.primaryColor;
              } else if (isSelectable) {
                textColor = AppColors.onBackgroundColor;
              } else {
                textColor = AppColors.dividerColor;
              }

              return GestureDetector(
                onTap: isSelectable
                    ? () {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    : null,
                child: Center(
                  child: Container(
                    width: 24.w,
                    height: 24.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.secondaryColor
                          : Colors.transparent,
                    ),
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14.sp,
                        height: 1,
                        fontWeight: (isSelected || isToday)
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // 5. UYARI YAZISI
        SizedBox(height: 10.h),
        Text(
          '* Yalnızca önümüzdeki 7 gün için Buluşma oluşturabilirsiniz',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryColor,
            fontFamily: 'SF Pro Display',
          ),
        ),

        // 6. SAAT SEÇİMİ
        SizedBox(height: 18.h),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isTimeUndefined)
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  width: 40.h,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: AppColors.inputFillColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.access_time,
                    color: AppColors.onBackgroundColor,
                    size: 24.sp,
                  ),
                ),
              )
            else
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      width: 112.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: AppColors.inputFillColor,
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 24.sp,
                            color: AppColors.onBackgroundColor,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            "${_selectedTime.hour.toString().padLeft(2, '0')} : ${_selectedTime.minute.toString().padLeft(2, '0')}",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onBackgroundColor,
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () => setState(() => _isTimeUndefined = true),
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      child: Icon(
                        Icons.close,
                        color: AppColors.secondaryColor,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),

        // 7. İLERLE BUTONU
        SizedBox(height: 18.h),

        PopupNextButton(
          onPressed: () {
            widget.onNext(
              _selectedDate,
              _isTimeUndefined ? null : _selectedTime,
              _isTimeUndefined,
            );
          },
        ),
      ],
    );
  }
}
