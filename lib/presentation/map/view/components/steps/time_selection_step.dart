import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/providers/get_it_init.dart'; // getIt için gerekli
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/services/session_service.dart'; // SessionService için gerekli
import 'package:outnest/presentation/map/view/components/popup_next_button.dart';

class TimeSelectionStep extends StatefulWidget {
  const TimeSelectionStep({
    required this.onBack,
    required this.onNext,
    this.onClose,
    this.hideCloseButton = false,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback? onClose;
  final Function(DateTime date, TimeOfDay? time, bool isTimeUndefined) onNext;
  final bool hideCloseButton;

  @override
  State<TimeSelectionStep> createState() => _TimeSelectionStepState();
}

class _TimeSelectionStepState extends State<TimeSelectionStep> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  late DateTime _now;
  bool _localeInitialized = false;

  // Sabit 7 günlük liste
  List<DateTime> _selectableDays = [];
  DateTime? _customSelectedDate;

  // Topluluk hesabı kontrolü
  bool _isCommunityAccount = false;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();

    // 1. ŞU AN GİRİŞ YAPAN KULLANICIYI ÇEK
    final currentUser = getIt<SessionService>().currentUser;

    // 2. KONTROL: Kullanıcı var mı ve hesabı topluluk hesabı mı?
    if (currentUser != null &&
        currentUser.accountType != null &&
        currentUser.accountType.toString().toLowerCase().contains(
          'community',
        )) {
      _isCommunityAccount = true;
    }

    // Başlangıçta önümüzdeki 7 günü dolduruyoruz
    _selectableDays = List.generate(
      7,
      (index) =>
          DateTime(_now.year, _now.month, _now.day).add(Duration(days: index)),
    );

    initializeDateFormatting('tr_TR').then((_) {
      if (mounted) {
        setState(() {
          _localeInitialized = true;
        });
      }
    });
  }

  void _pickCustomDate() {
    var initialDate = _customSelectedDate ?? _selectableDays.last;

    final minDate = DateTime(_now.year, _now.month, _now.day);

    if (initialDate.isBefore(minDate)) {
      initialDate = minDate;
    }

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        padding: const EdgeInsets.only(top: 6),
        color: AppColors.popupSurface,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  child: const Text("Tamam"),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: initialDate,
                  mode: CupertinoDatePickerMode.date,
                  minimumDate: minDate,
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      final pickedDate = DateTime(
                        newDate.year,
                        newDate.month,
                        newDate.day,
                      );

                      // Seçilen tarih ilk 7 gün içinde mi kontrol et
                      final bool isInFirst7Days = _selectableDays.any(
                        (d) => _isSameDay(d, pickedDate),
                      );

                      if (isInFirst7Days) {
                        _customSelectedDate = null;
                        _selectedDate = pickedDate;
                      } else {
                        _customSelectedDate = pickedDate;
                        _selectedDate = pickedDate;
                      }
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

  void _pickTime() {
    final now = DateTime.now();
    final isSelectingToday = _isSameDay(_selectedDate, now);
    final initialDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final minDate = isSelectingToday
        ? now
        : DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

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
                  initialDateTime: initialDateTime.isBefore(minDate)
                      ? minDate
                      : initialDateTime,
                  mode: CupertinoDatePickerMode.time,
                  minimumDate: minDate,
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      _selectedTime = TimeOfDay.fromDateTime(newDate);
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

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
                  Symbols.reply, // Material Symbols İkonu
                  size: 24.sp,
                  color: AppColors.iconColor,
                ),
              ),
            ),
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

        SizedBox(height: 24.h),
        Text(
          "Tarih",
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.onBackgroundColor,
          ),
        ),
        SizedBox(height: 16.h),

        // 3. TARİH KUTULARI
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Wrap(
              spacing: 12.w,
              runSpacing: 16.h,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Sabit 7 günlük liste
                ..._selectableDays.map((date) => _buildDateCard(date)),

                // --- 8. ELEMAN: Özel Dönüşen Buton (Herkes görür ama yetkisi olan tıklar) ---
                _buildDynamicCustomDateButton(),
              ],
            ),
          ),
        ),

        // 4. UYARI YAZISI (Kullanıcı Tipi Odaklı)
        SizedBox(height: 10.h),
        if (!_isCommunityAccount)
          Text(
            '* Sadece önümüzdeki 7 gün için Buluşma oluşturabilirsiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryColor,
              fontFamily: 'SF Pro Display',
            ),
          ),
        if (_isCommunityAccount)
          Text(
            '* Topluluk hesapları herhangi bir ileri tarih için Buluşma oluşturabilir.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryColor,
              fontFamily: 'SF Pro Display',
            ),
          ),

        SizedBox(height: 16.h),
        Text(
          "Saat",
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.onBackgroundColor,
          ),
        ),
        SizedBox(height: 12.h),

        // 5. SAAT SEÇİMİ BUTONU
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                width: 112.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: AppColors.inputFillColor,
                  borderRadius: BorderRadius.circular(6.r),
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
                        fontWeight: FontWeight.w500,
                        color: AppColors.onBackgroundColor,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // 6. İLERLE BUTONU
        SizedBox(height: 18.h),
        PopupNextButton(
          onPressed: () {
            widget.onNext(_selectedDate, _selectedTime, false);
          },
        ),
      ],
    );
  }

  // --- TARİH KUTUCUKLARI ---
  Widget _buildDateCard(DateTime date) {
    final isSelected = _isSameDay(_selectedDate, date);
    final isToday = _isSameDay(_now, date);

    final dayStr = DateFormat('d MMM', 'tr_TR').format(date);
    final weekdayStr = DateFormat('EEEE', 'tr_TR').format(date);

    return GestureDetector(
      onTap: () => setState(() => _selectedDate = date),
      child: Container(
        width: 60.w,
        height: 48.h,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.tertiaryColor : const Color(0xFFF3F5F7),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            // BUGÜN VE SEÇİLİ DEĞİLSE turuncu çerçeve göster
            color: (isToday && !isSelected)
                ? AppColors.primaryColor
                : Colors.transparent,
            width: 1.5.w,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayStr,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.onBackgroundColor,
                fontFamily: 'SF Pro Display',
              ),
            ),
            Text(
              weekdayStr,
              maxLines: 1,
              style: TextStyle(
                fontSize: 8.sp,
                color: isSelected ? Colors.white : AppColors.onBackgroundColor,
                fontFamily: 'SF Pro Display',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ÖZEL TARİH (+) BUTONU VEYA SEÇİLMİŞ HALİ ---
  Widget _buildDynamicCustomDateButton() {
    if (_customSelectedDate == null) {
      return GestureDetector(
        // Topluluk hesabıysa tıklanabilir
        onTap: _isCommunityAccount ? _pickCustomDate : null,
        child: Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F5F7),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.black12, width: 0.5),
          ),
          child: Icon(
            Icons.add,
            // Topluluk değilse
            color: AppColors.onBackgroundColor.withOpacity(
              _isCommunityAccount ? 0.5 : 0.15,
            ),
            size: 18.sp,
          ),
        ),
      );
    } else {
      final isSelected = _isSameDay(_selectedDate, _customSelectedDate!);
      final isToday = _isSameDay(_now, _customSelectedDate!);

      final dayStr = DateFormat('d MMM', 'tr_TR').format(_customSelectedDate!);
      final weekdayStr = DateFormat(
        'EEEE',
        'tr_TR',
      ).format(_customSelectedDate!);

      return GestureDetector(
        onTap: () {
          if (isSelected) {
            _pickCustomDate();
          } else {
            setState(() => _selectedDate = _customSelectedDate!);
          }
        },
        child: Container(
          width: 64.w,
          height: 48.h,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.tertiaryColor
                : const Color(0xFFF3F5F7),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: (isToday && !isSelected)
                  ? AppColors.primaryColor
                  : Colors.transparent,
              width: 1.5.w,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dayStr,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : AppColors.onBackgroundColor,
                  fontFamily: 'SF Pro Display',
                ),
              ),
              Text(
                weekdayStr,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 8.sp,
                  color: isSelected
                      ? Colors.white
                      : AppColors.onBackgroundColor,
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
