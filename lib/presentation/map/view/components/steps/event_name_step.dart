import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/presentation/map/view/components/popup_next_button.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/services/remote_config_service.dart';

class EventNameStep extends StatefulWidget {
  const EventNameStep({
    required this.onBack,
    required this.onClose,
    required this.onNext,
    required this.category,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onClose;
  final String category;
  final Function(String eventName, bool isSuggestionUsed) onNext;

  @override
  State<EventNameStep> createState() => _EventNameStepState();
}

class _EventNameStepState extends State<EventNameStep> {
  final TextEditingController _controller = TextEditingController();

  // Örnek öneriler (Dinamik halde kullanılabilir)
  List<String> _suggestions = [];
  bool _isNameSuggestionUsed = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final remoteConfig = getIt<RemoteConfigService>();
    final allSuggestions = await remoteConfig.getValue<Map>('category_names');

    // widget.category değerinin (Örn: "Kahve") Map içinde olup olmadığını kontrol edin
    final categorySuggestions =
        allSuggestions[widget.category] as List<dynamic>?;

    if (categorySuggestions != null) {
      final suggestions = categorySuggestions
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();

      setState(() {
        _suggestions = suggestions;
      });
    } else {
      print(
        "Hata: ${widget.category} kategorisi Firebase'deki Map içinde bulunamadı.",
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // 1. HEADER (Geri - Başlık - Kapat)
        Stack(
          alignment: Alignment.center,
          children: [
            // Sol: Geri Butonu
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

            // Orta: Başlık
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.short_text_rounded,
                  size: 24.sp,
                  color: AppColors.iconColor,
                ),
                SizedBox(width: 4.w),
                Text(
                  'Buluşma Adı',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onBackgroundColor,
                  ),
                ),
              ],
            ),

            // Sağ: Kapat Butonu
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

        // 2. INPUT ALANI
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5), // Açık gri zemin
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: TextField(
            controller: _controller,
            textAlign: TextAlign.center,
            onChanged: (value) => setState(() {
              _isNameSuggestionUsed = false;
            }),
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: _suggestions.isNotEmpty
                  ? 'Örn: ${_suggestions.first}'
                  : 'Buluşma adını girin',
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
            ),
          ),
        ),

        SizedBox(height: 32.h),

        // 3. ÖNERİLER BAŞLIĞI
        Text(
          'İnsanların ilgisini çekebilecek öneriler:',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.black87,
            fontWeight: FontWeight.w400,
          ),
        ),

        SizedBox(height: 16.h),

        // 4. ÖNERİLER LİSTESİ
        ..._suggestions.map((suggestion) {
          return Column(
            children: [
              GestureDetector(
                onTap: () {
                  // Öneriye tıklayınca inputa yaz
                  _controller.text = suggestion;
                  // İmleci sona taşı
                  _controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: _controller.text.length),
                  );
                  setState(() {
                    _isNameSuggestionUsed = true;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.tertiaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // Son eleman değilse çizgi koy
              if (suggestion != _suggestions.last)
                Divider(
                  color: Colors.grey.shade300,
                  thickness: 1,
                  indent: 40.w,
                  endIndent: 40.w,
                ),
            ],
          );
        }),

        const Spacer(),

        // 5. İLERLE BUTONU
        PopupNextButton(
          onPressed: () {
            // Boş kontrolü yapılabilir
            widget.onNext(_controller.text, _isNameSuggestionUsed);
          },
        ),
      ],
    );
  }
}
