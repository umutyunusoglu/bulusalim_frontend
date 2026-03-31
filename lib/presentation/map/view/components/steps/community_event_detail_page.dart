import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/presentation/map/view/components/popup_next_button.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';
import 'package:outnest/presentation/shared/form/sanitizer.dart';

class CommunityEventDetailPage extends HookWidget {
  const CommunityEventDetailPage({
    required this.args,
    super.key,
  });

  final Map<String, dynamic> args;

  @override
  Widget build(BuildContext context) {
    final coverImage = useState<File?>(null);
    final descController = useTextEditingController();
    final rulesController = useTextEditingController(text: '• ');
    final venueController = useTextEditingController();
    final linkController = useTextEditingController();
    final maxParticipants = useState<int?>(null);
    final requiresDocument = useState(false);

    useEffect(() {
      void onRulesChanged() {
        final text = rulesController.text;
        if (text.endsWith('\n')) {
          final newText = '$text• ';
          rulesController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newText.length),
          );
        }
      }

      rulesController.addListener(onRulesChanged);
      return () => rulesController.removeListener(onRulesChanged);
    }, []);

    useListenable(descController);
    final isFormValid = descController.text.trim().isNotEmpty;

    final pickImage = useCallback(() async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null) coverImage.value = File(picked.path);
    }, []);

    Future<void> onNext() async {
      if (!context.mounted) return;

      final linkRaw = linkController.text.trim();
      String linkValue = '';
      if (linkRaw.isNotEmpty) {
        final sanitized = sanitizeUrl(linkRaw);
        if (sanitized == null) {
          showErrorPopup(context, message: 'Geçersiz bağlantı adresi');
          return;
        }
        linkValue = sanitized;
      }

      await context.push(
        '/community-event-detail-preview',
        extra: {
          'description': sanitizeInput(descController.text),
          'rules': sanitizeInput(rulesController.text),
          'venueInfo': sanitizeInput(venueController.text),
          'link': linkValue,
          'maxParticipants': maxParticipants.value ?? 0,
          'requiresDocument': requiresDocument.value,
          'coverImage': coverImage.value,
          'eventName': args['eventName'],
          'displayAddress': args['displayAddress'],
          'startTime': args['startTime'],
          'category': args['category'],
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Symbols.reply,
            color: AppColors.onBackgroundColor,
          ),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline,
              size: 20,
              color: AppColors.onBackgroundColor,
            ),
            SizedBox(width: 4.w),
            Text(
              'Buluşma Bilgileri',
              style: TextStyle(
                color: AppColors.onBackgroundColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Symbols.close,
              color: AppColors.onBackgroundColor,
            ),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FOTOĞRAF
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      height: 174.h,
                      width: 174.w,
                      decoration: BoxDecoration(
                        color: AppColors.inputFillColor,
                        borderRadius: BorderRadius.circular(6.r),
                        image: coverImage.value != null
                            ? DecorationImage(
                                image: FileImage(coverImage.value!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: coverImage.value == null
                          ? Icon(
                              Icons.image_outlined,
                              size: 40.sp,
                              color: AppColors.textGrey,
                            )
                          : null,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: pickImage,
                    child: Text(
                      '+ fotoğraf ekle',
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            _buildLabel('Buluşma Hakkında *'),
            _buildExpandingTextField(descController),
            SizedBox(height: 16.h),

            _buildLabel('Katılım Kuralları & Gereklilikler'),
            _buildExpandingTextField(rulesController),
            SizedBox(height: 16.h),

            _buildLabel('Mekan Bilgileri'),
            _buildExpandingTextField(venueController),
            SizedBox(height: 16.h),

            _buildLabel('Bağlantı Ekle'),
            _buildExpandingTextField(linkController, hint: 'https://...'),
            SizedBox(height: 16.h),

            // MAKSİMUM KATILIMCI
            _buildLabel('Maksimum Katılımcı Sayısı'),
            SizedBox(
              width: 329.w,
              height: 40.h,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: const Color(0xFFC6D0D9)),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Text(
                        maxParticipants.value != null
                            ? '${maxParticipants.value} kişi'
                            : '',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.onBackgroundColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => maxParticipants.value =
                            (maxParticipants.value ?? 0) + 1,
                        child: const Icon(
                          Icons.keyboard_arrow_up,
                          size: 20,
                          color: AppColors.iconColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (maxParticipants.value != null &&
                              maxParticipants.value! > 1) {
                            maxParticipants.value = maxParticipants.value! - 1;
                          } else {
                            maxParticipants.value = null;
                          }
                        },
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: AppColors.iconColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            // BELGE ZORUNLULUĞU
            Row(
              children: [
                Theme(
                  data: Theme.of(context).copyWith(
                    checkboxTheme: CheckboxThemeData(
                      fillColor: WidgetStateProperty.all(
                        const Color(0xFFF2F2F7),
                      ),
                      checkColor: WidgetStateProperty.all(
                        AppColors.onBackgroundColor,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      side: BorderSide.none,
                    ),
                  ),
                  child: Checkbox(
                    value: requiresDocument.value,
                    onChanged: (v) => requiresDocument.value = v ?? false,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Katılabilmek için belge yüklemek zorunlu olsun.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.onBackgroundColor,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // İLERLE BUTONU
            Center(
              child: PopupNextButton(
                onPressed: isFormValid ? () async => onNext() : null,
              ),
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: EdgeInsets.only(bottom: 6.h),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.onBackgroundColor,
      ),
    ),
  );

  Widget _buildExpandingTextField(
    TextEditingController controller, {
    String? hint,
  }) => SizedBox(
    width: 361.w,
    child: TextField(
      cursorColor: AppColors.onBackgroundColor,
      controller: controller,
      maxLines: null,
      minLines: 1,
      keyboardType: TextInputType.multiline,
      style: TextStyle(
        fontSize: 14.sp,
        color: AppColors.onBackgroundColor,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textGrey,
          fontSize: 14.sp,
        ),
        fillColor: Colors.transparent,
        filled: false,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 10.h,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Color(0xFFC6D0D9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Color(0xFFC6D0D9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: AppColors.secondaryColor),
        ),
      ),
    ),
  );
}
