import 'dart:io';
import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/core/constants/constant.dart'; // Constant dosyasını import ediyoruz
import 'package:bulusalim/core/utils/types/enums/feed_type.dart';
import 'package:bulusalim/domain/entities/feed/post/post_entity.dart';
import 'package:bulusalim/domain/entities/hobby/hobby_entity.dart';
import 'package:bulusalim/domain/repositories/post_repository.dart';
import 'package:bulusalim/domain/services/auth_service.dart';
import 'package:bulusalim/domain/services/session_service.dart';
import 'package:bulusalim/domain/usecases/upload_post_usecase.dart';
import 'package:bulusalim/screens/home/home_content_page.dart';
import 'package:bulusalim/screens/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NewPostPage extends StatefulWidget {
  const NewPostPage({
    this.takenPhotos = const [],
    super.key,
  });
  final List<File> takenPhotos;

  @override
  State<NewPostPage> createState() => _NewPostPageState();
}

class _NewPostPageState extends State<NewPostPage> {
  final TextEditingController _captionController = TextEditingController();
  final PageController _pageController = PageController();

  List<File> _selectedMedia = [];
  int _currentImageIndex = 0;
  bool _showParticipants = false;
  bool _addToDump = false;

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

  ImageProvider _getImageProvider(dynamic media) {
    if (media is File) {
      return FileImage(media);
    } else {
      return NetworkImage(media as String);
    }
  }

  Widget _buildImageWidget(dynamic media, BoxFit fit) {
    if (media is File) {
      return Image.file(media, fit: fit);
    } else {
      return Image.network(
        media as String,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
          child: Column(
            children: [
              // --- BAŞLIK ALANI ---
              SizedBox(
                height: 40.h,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Yeni Gönderi',
                        style: kLoginTextStyle.copyWith(fontSize: 20.sp),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(context),
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

              SizedBox(height: 4.h),

              // 1. FOTOĞRAF ALANI (361x361)
              if (_selectedMedia.isNotEmpty)
                Container(
                  height: 361.h,
                  width: 361.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _selectedMedia.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return _buildImageWidget(
                          _selectedMedia[index],
                          BoxFit.cover,
                        );
                      },
                    ),
                  ),
                )
              else
                Container(
                  height: 361.h,
                  width: 361.w,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(
                      'Fotoğraf Yok',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontFamily: 'Urbanist',
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 8.h),

              // 2. SAYFA NOKTALARI
              if (_selectedMedia.length > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_selectedMedia.length, (index) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      width: 5.w,
                      height: 5.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == index
                            ? Colors.grey.shade800
                            : Colors.grey.shade300,
                      ),
                    );
                  }),
                )
              else
                SizedBox(height: 5.w),

              SizedBox(height: 8.h),

              // 3. AÇIKLAMA ALANI
              Container(
                height: 68.h,
                width: 361.w,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Stack(
                  children: [
                    // TextField
                    Positioned.fill(
                      child: TextField(
                        controller: _captionController,
                        maxLength: 50,
                        maxLines: 2,
                        textAlignVertical: TextAlignVertical.top,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontFamily: 'Urbanist',
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Açıklama yaz.',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14.sp,
                            fontFamily: 'Urbanist',
                          ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.only(right: 40.w),
                          counterText: '',
                        ),
                      ),
                    ),
                    // Karakter Sayacı
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ValueListenableBuilder(
                        valueListenable: _captionController,
                        builder: (context, TextEditingValue value, _) {
                          return Text(
                            '${value.text.length}/50',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12.sp,
                              fontFamily: 'Urbanist',
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 18.h),

              // 4. KATILIMCILARI GÖSTER
              _buildCustomSwitchTile(
                title: 'Katılımcıları göster.',
                subtitle:
                    'Bunu kabul ederek katıldığın etkinlikte bulunan diğer katılımcılar paylaşımında yer alacak ve diğer kullanıcılar tarafından görüntülenebilecek.',
                value: _showParticipants,
                onChanged: (val) => setState(() => _showParticipants = val),
              ),

              SizedBox(height: 8.h),

              // 5. DUMP'A DAHİL ET (Yazılarınız korundu)
              _buildCustomSwitchTile(
                title: "Dump'a dahil et.",
                subtitle:
                    'Bunu kabul ederek paylaştığın gönderideki fotoğrafların ay sonunda senin için hazırlayacağımız dump gönderisine dahil olmasına izin verirsin. Seçtiğin 3.fotoğraf Dump’larda yer almayacak.)',
                value: _addToDump,
                onChanged: (val) => setState(() => _addToDump = val),
              ),

              const Spacer(),

              // 6. PAYLAŞ BUTONU
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        spreadRadius: 0,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 240.w,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: _selectedMedia.isEmpty
                          ? null
                          : () {
                              _sendPost();
                              debugPrint('Paylaşılıyor...');
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kButtonBackgroundColor,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        elevation: 0,
                        alignment: Alignment.center,
                      ),
                      child: Text(
                        'paylaş',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Urbanist',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      width: 361.w, // İçeriği de 361w genişliğine sabitledim
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontFamily: 'Urbanist',
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade600,
                    height: 1.1,
                    fontFamily: 'Urbanist',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: kButtonBackgroundColor,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFE7E7E7),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              trackOutlineWidth: WidgetStateProperty.all(0),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPost() async {
    final uploadPost = getIt<UploadPost>();

    await uploadPost(
      _selectedMedia,
      _showParticipants,
      _addToDump,
      _captionController.text.trim(),
    );
    if (!mounted) return;
    await Navigator.pushAndRemoveUntil(
      context,

      MaterialPageRoute<void>(
        builder: (context) => const HomePage(),
      ), // Buraya kendi ana sayfa widget ismini yaz
      (Route<dynamic> route) =>
          false, // false: Geriye dönük tüm sayfaları sil demektir
    );
  }
}
