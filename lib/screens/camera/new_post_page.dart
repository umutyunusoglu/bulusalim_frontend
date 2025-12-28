import 'dart:io';
import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/core/constants/configs/app_config.dart';
import 'package:bulusalim/core/utils/debug/android_image_url_fixer.dart';
import 'package:bulusalim/domain/usecases/upload_post_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

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

  Widget _buildImageWidget(dynamic media, BoxFit fit) {
    if (media is File) {
      return Image.file(media, fit: fit);
    } else {
      return Image.network(
        fixEmulatorUrl(media as String),
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.secondary,
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final headerColor = colorScheme.tertiary;
    final actionColor = colorScheme.secondary;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
          child: Column(
            children: [
              // --- 1. BAŞLIK ALANI ---
              SizedBox(
                height: 30.h,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      child: Text(
                        'Yeni Gönderi',
                        style: TextStyle(
                          fontFamily: 'Urbanist',
                          fontWeight: FontWeight.bold,
                          fontSize: 20.sp,
                          color: headerColor,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        // YENİ: GoRouter ile kapatma
                        onPressed: () => context.pop(),
                        icon: Icon(
                          Icons.close,
                          color: headerColor,
                          size: 26.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // --- 2. FOTOĞRAF ALANI ---
              Container(
                height: 361.h,
                width: 361.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
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
              ),

              SizedBox(height: 8.h),

              // --- 3. SAYFA NOKTALARI ---
              if (_selectedMedia.length > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_selectedMedia.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: 3.w),
                      width: 5.w,
                      height: 5.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == index
                            ? Colors.grey.shade400
                            : Colors.grey.shade300,
                      ),
                    );
                  }),
                )
              else
                SizedBox(height: 5.h),

              SizedBox(height: 8.h),

              // --- 4. AÇIKLAMA ALANI ---
              Container(
                height: 60.h,
                width: 361.w,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(),
                ),
                child: Stack(
                  children: [
                    TextField(
                      controller: _captionController,
                      maxLength: AppConfig.maxPostCaptionLength,
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontFamily: 'Urbanist',
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        filled: false,
                        hintText: 'Açıklama yaz.',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14.sp,
                          fontFamily: 'Urbanist',
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        counterText: '',
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ValueListenableBuilder(
                        valueListenable: _captionController,
                        builder: (context, TextEditingValue value, _) {
                          return Text(
                            '${value.text.length}/+${AppConfig.maxPostCaptionLength}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10.sp,
                              fontFamily: 'Urbanist',
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // --- 5. SWITCHLER ---
              _buildSwitchOption(
                context,
                title: 'Katılımcıları göster.',
                subtitle:
                    'Bunu kabul ederek katıldığın etkinlikte bulunan diğer katılımcılar paylaşımında yer alacak ve diğer kullanıcılar tarafından görüntülenebilecek.',
                value: _showParticipants,
                onChanged: (val) => setState(() => _showParticipants = val),
                activeColor: actionColor,
              ),

              SizedBox(height: 16.h),

              _buildSwitchOption(
                context,
                title: "Dump'a dahil et.",
                subtitle:
                    "Bunu kabul ederek paylaştığın gönderideki fotoğrafların ay sonunda senin için hazırlayacağımız dump gönderisine dahil olmasına izin verirsin. Seçtiğin 3.fotoğraf Dump'larda yer almayacak.)",
                value: _addToDump,
                onChanged: (val) => setState(() => _addToDump = val),
                activeColor: actionColor,
              ),

              const Spacer(),

              SizedBox(height: 10.h),

              // --- 6. PAYLAŞ BUTONU ---
              SizedBox(
                width: 173.w,
                height: 40.h,
                child: ElevatedButton(
                  onPressed: () {
                    _sendPost();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                  ),
                  child: Text(
                    'paylaş',
                    style: TextStyle(
                      fontFamily: 'Urbanist',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color activeColor,
  }) {
    return SizedBox(
      width: 361.w,
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
                    fontFamily: 'Urbanist',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: activeColor,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade300,
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
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
    context.go('/home');
  }
}
