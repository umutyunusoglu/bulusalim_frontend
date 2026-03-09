import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/repositories/group_repository.dart';
import 'package:outnest/presentation/map/view/components/popup_next_button.dart';

class VisibilitySelectionStep extends StatefulWidget {
  const VisibilitySelectionStep({
    required this.onBack,
    required this.onNext,
    this.onClose,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback? onClose;
  // DÜZELTME 1: Grup seçilmediği durumlar için String yerine String? (nullable) yapıldı.
  final void Function(
    String visibility,
    String? selectedGroup,
    bool isMapHidden,
  )
  onNext;

  @override
  State<VisibilitySelectionStep> createState() =>
      _VisibilitySelectionStepState();
}

class _VisibilitySelectionStepState extends State<VisibilitySelectionStep> {
  String _selectedVisibility = 'herkes';
  bool _isMapHidden = false;

  List<String>? _myGroups;

  // Seçilen grubu tutan değişken (Liste yerine tek bir String)
  String? _selectedGroup;

  final List<String> _options = [
    'herkes',
    'takipçiler',
    'okul',
    'gruplar',
  ];

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final groups = await getIt<GroupRepository>().getMyGroups();
    setState(() {
      _myGroups = groups;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const activeColor = AppColors.tertiaryColor;

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
                  Icons.visibility_outlined,
                  size: 24.sp,
                  color: AppColors.iconColor,
                ),
                SizedBox(width: 4.w),
                Text(
                  'Buluşma Görünürlüğü',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onBackgroundColor,
                  ),
                ),
              ],
            ),

            // SAĞ BUTON (Kapat)
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

        SizedBox(height: 32.h),

        // 2. ANA SEÇENEK BUTONLARI
        ..._options.map((option) {
          final isSelected = _selectedVisibility == option;
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedVisibility = option;
                  if (option != 'gruplar') {
                    _selectedGroup = null;
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 173.w,
                height: 33.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  // Seçiliyse Mavi Opak, değilse Gri
                  color: isSelected
                      ? activeColor.withOpacity(0.15)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12.r),
                  border: isSelected ? Border.all(color: activeColor) : null,
                  boxShadow: (isSelected && option == 'gruplar')
                      ? [
                          BoxShadow(
                            color: activeColor.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  option,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? activeColor
                        : AppColors.onBackgroundColor,
                  ),
                ),
              ),
            ),
          );
        }),

        if (_selectedVisibility == 'gruplar') ...[
          SizedBox(height: 8.h),
          if (_myGroups == null)
            const CircularProgressIndicator()
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ..._myGroups!.map((group) {
                    // DÜZELTME 2: Liste mantığı yerine tekli seçim mantığı eklendi
                    final isGroupSelected = _selectedGroup == group;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          // DÜZELTME 3: Eğer zaten seçiliyse seçimi kaldır, değilse o grubu seç
                          if (isGroupSelected) {
                            _selectedGroup = null;
                          } else {
                            _selectedGroup = group;
                          }
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: isGroupSelected
                              ? activeColor // Seçiliyse Mavi
                              : const Color(0xFFF5F5F5), // Değilse Gri
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          group,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isGroupSelected
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }),

                  SizedBox(width: 4.w),

                  // ARTI (+) BUTONU
                  GestureDetector(
                    onTap: () {
                      context.push("/groups");
                    },
                    child: Icon(
                      Icons.add,
                      size: 20.sp,
                      color: activeColor,
                    ),
                  ),
                ],
              ),
            ),
        ],

        const Spacer(),

        // 4. HARİTADA GÖSTERME CHECKBOX
        GestureDetector(
          onTap: () {
            setState(() {
              _isMapHidden = !_isMapHidden;
              // TODO: Harita gizliliği mantığı buraya eklenebilir.
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 18.w,
                height: 18.w,
                decoration: BoxDecoration(
                  color: _isMapHidden ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border.all(
                    color: _isMapHidden ? activeColor : Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
                child: _isMapHidden
                    ? Icon(Icons.check, size: 14.sp, color: Colors.white)
                    : null,
              ),
              SizedBox(width: 8.w),
              Text(
                'Buluşmayı haritada gösterme.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.onBackgroundColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),

        // 5. İLERLE BUTONU
        PopupNextButton(
          onPressed: () {
            widget.onNext(
              _selectedVisibility,
              _selectedGroup,
              _isMapHidden,
            );
          },
        ),
      ],
    );
  }
}
