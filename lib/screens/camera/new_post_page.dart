import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/components/apple_toast_popup.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/services/draft_post_service.dart';
import 'package:outnest/domain/usecases/upload_post_usecase.dart';

class NewPostPage extends StatefulWidget {
  const NewPostPage({
    required this.event,
    this.takenPhotos = const [],
    super.key,
  });
  final List<File> takenPhotos;
  final EventEntity event;

  @override
  State<NewPostPage> createState() => _NewPostPageState();
}

class _NewPostPageState extends State<NewPostPage> {
  final TextEditingController _captionController = TextEditingController();
  final PageController _pageController = PageController();

  List<File> _selectedMedia = [];
  int _currentImageIndex = 0;
  bool _showParticipants = true;
  bool _addToDump = true;
  bool _pinPhoto = true;

  @override
  void initState() {
    super.initState();
    _selectedMedia = List.from(widget.takenPhotos);
  }

  @override
  void dispose() {
    _captionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Klavye taşmasını önler
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              // --- ÜST BAR ---
              SizedBox(
                height: 50.h,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'Yeni Gönderi',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                        color: Colors.black,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 24.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- FOTOĞRAF (361x361) ---
              Container(
                height: 330.h, // Ekran yüksekliğine göre 361.w ile orantılandı
                width: 361.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.r),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.r),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _selectedMedia.length,
                    onPageChanged: (index) =>
                        setState(() => _currentImageIndex = index),
                    itemBuilder: (context, index) => Image.file(
                      _selectedMedia[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 8.h),

              // Sayfa Noktaları
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _selectedMedia.length,
                  (index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: 2.w),
                    width: 6.w,
                    height: 6.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index
                          ? Colors.black
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12.h),

              // --- INPUT ALANI (Tam Ölçü: 361x68) ---
              Container(
                height: 68.h,
                width: 361.w,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7), // Görseldeki açık gri tonu
                  borderRadius: BorderRadius.circular(
                    20.r,
                  ), // Görseldeki yumuşak köşe
                ),
                child: Stack(
                  children: [
                    TextField(
                      controller: _captionController,
                      maxLength: 50,
                      maxLines: 2,
                      cursorColor: Colors.grey,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 15.sp,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Açıklama yaz.',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontFamily: 'SF Pro Display',
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        counterText: '', // Standart sayacı gizle
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) => setState(() {}),
                    ),
                    // Sağ alt köşedeki karakter sayacı (0/50)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Text(
                        '${_captionController.text.length}/50',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12.sp,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // --- SWITCHLER ---
              _buildSwitchRow(
                'Katılımcıları göster.',
                'Katıldığın buluşmada bulunan diğer katılımcılar paylaşımında yer alacak.',
                _showParticipants,
                (v) => setState(() => _showParticipants = v),
              ),
              _buildSwitchRow(
                "Dump'a dahil et.",
                'Paylaştığın gönderideki fotoğrafların ay sonunda senin için hazırlayacağımız dump gönderisine dahil olur.',
                _addToDump,
                (v) => setState(() => _addToDump = v),
              ),
              _buildSwitchRow(
                'Profile sabitle.',
                'Paylaştığın gönderi 1 gün sonra profilinden silinmeyecek.',
                _pinPhoto,
                (v) => setState(() => _pinPhoto = v),
              ),

              const Spacer(),

              // --- PAYLAŞ BUTONU ---
              SizedBox(
                width: 170.w,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: _sendPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C86A4),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: Text(
                    'paylaş',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchRow(
    String title,
    String sub,
    bool val,
    Function(bool) onCh,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    color: Colors.grey.shade500,
                    fontSize: 10.sp,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: val,
              onChanged: onCh,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFFFF7A5C),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPost() async {
    final uploadPost = getIt<UploadPost>();
    final draftService = getIt<DraftPostService>();

    // Widget dispose olmadan önce messenger'ı ve verileri kopyala
    final messenger = ScaffoldMessenger.of(context);
    final event = widget.event;
    final media = List<File>.from(_selectedMedia);
    final caption = _captionController.text.trim();

    // 1. Kullanıcıya "Başlıyoruz" bilgisi ver
    showAppleToast(messenger, 'Paylaşılıyor...');

    // 2. Sayfayı hemen kapat
    context.go('/home');

    // 3. Arka planda işlemi yürüt
    try {
      await uploadPost(
        event,
        media,
        _showParticipants,
        _addToDump,
        _pinPhoto,
        caption,
      );

      // Başarılı ise taslağı temizle ve haber ver
      await draftService.clearDraft(event.id);
      showAppleToast(messenger, 'Paylaşıldı!');
    } catch (e) {
      // Hata durumunda uyar
      showAppleToast(
        messenger,
        'Hata oluştu, tekrar deneniyor.',
        isError: true,
      );
      // Not: Burada retry mekanizması veya taslağı koruma mantığı eklenebilir.
    }
  }
}
