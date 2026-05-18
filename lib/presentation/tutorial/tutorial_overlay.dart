import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/presentation/shared/action_buttons_speed_dial.dart';

class TutorialOverlay extends HookWidget {
  const TutorialOverlay({
    required this.onDismiss,
    super.key,
  });

  final VoidCallback onDismiss;

  static const int _totalPages = 4;

  @override
  Widget build(BuildContext context) {
    final pageController = usePageController();
    final currentPage = useState(0);
    final previousPage = useState(0); // YENİ
    final hasOpenedDial = useState(false);
    final dialEverClosed = useState(false);

    final isDialOpen = useMemoized(() => ValueNotifier(false));

    useEffect(() {
      void listener() {
        if (isDialOpen.value) {
          hasOpenedDial.value = true;
        } else if (hasOpenedDial.value) {
          dialEverClosed.value = true;
        }
      }

      isDialOpen.addListener(listener);
      return () => isDialOpen.removeListener(listener);
    }, []);

    return Material(
      color: AppColors.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // HEADER — atla / bitti
            Padding(
              padding: EdgeInsets.only(top: 22.h, right: 20.w),
              child: Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () async {
                    if (currentPage.value == _totalPages - 1) {
                      onDismiss();
                    } else {
                      pageController.jumpToPage(_totalPages - 1);
                    }
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      currentPage.value == _totalPages - 1 ? 'bitti' : 'atla',
                      key: ValueKey(currentPage.value == _totalPages - 1),
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: previousPage.value < currentPage.value
                  ? const Duration(milliseconds: 150)
                  : Duration.zero, // geri giderken anında
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: AnimatedOpacity(
                duration: previousPage.value < currentPage.value
                    ? const Duration(milliseconds: 150)
                    : Duration.zero, // geri giderken anında
                opacity: currentPage.value != 0 ? 1.0 : 0.0,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Text(
                    'Outnest',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
            ),

            // SAYFALAR
            Expanded(
              child: PageView(
                controller: pageController,
                onPageChanged: (i) {
                  previousPage.value = currentPage.value; // YENİ
                  currentPage.value = i;
                },
                children: [
                  _buildPage1(isDialOpen, hasOpenedDial, dialEverClosed),
                  _buildDualFeaturePage(
                    topTitle: 'Buluşmalara Katıl',
                    topDesc:
                        'Etrafındaki buluşmaları keşfet ve ilgini çekenlere katıl. Yeni insanlarla tanışmak sadece bir dokunuş uzağında.',
                    topImagePath: 'assets/tutorial/tutorial_map.png',
                    bottomTitle: 'Buluşma Oluştur',
                    bottomDesc:
                        'Kendi buluşmanı planla ve insanları davet et. Yer, zaman ve detayları ekle; gerisini Outnest halleder.',
                    bottomImagePath: 'assets/tutorial/tutorial_category.png',
                    bottomSecondImagePath: 'assets/tutorial/tutorial_date.png',
                  ),
                  _buildDualFeaturePage(
                    topTitle: 'Buluşma Davetleri',
                    topDesc:
                        'Buluşmana katılmak isteyenleri Buluşmalarım sayfasından gör, kabul et ya da reddet. Kimin geleceğini sen belirle.',
                    topImagePath: 'assets/tutorial/tutorial_requests.png',
                    bottomTitle: 'Mesajlar',
                    bottomDesc:
                        'Katıldığın buluşmalar için özel bir sohbet açılır. Buluşma öncesinde konuşabilir, buluşma bittikten sonra ise 24 saat daha sohbet etmeye devam edebilirsin.',
                    bottomImagePath: 'assets/tutorial/tutorial_chat.png',
                  ),
                  _buildDualFeaturePage(
                    topTitle: 'QR Doğrulama',
                    topDesc:
                        'Buluşmada yan yana geldiğinde QR kodunu aç ve okut. Böylece buluşmaya gerçekten katıldığın doğrulanır.',
                    topImagePath: 'assets/tutorial/tutorial_qr.png',
                    bottomTitle: 'Fotoğraf Paylaş',
                    bottomDesc:
                        'Buluşmada çektiğin fotoğrafları paylaş. Hepsini aynı anda ya da gün içinde çekip sonra birlikte yayınlayabilirsin. Sabitlemezsen gönderiler 24 saat sonra kaybolur.',
                    bottomImagePath: 'assets/tutorial/tutorial_camera.png',
                  ),
                ],
              ),
            ),

            // DOTS
            Padding(
              padding: EdgeInsets.only(bottom: 24.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalPages,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: currentPage.value == i
                          ? AppColors.primaryColor
                          : AppColors.dividerColor.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // DİNAMİK BUTON EKRANI (Sayfa 1)
  Widget _buildPage1(
    ValueNotifier<bool> isDialOpen,
    ValueNotifier<bool> hasOpenedDial,
    ValueNotifier<bool> dialEverClosed,
  ) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDialOpen,
      builder: (context, isOpen, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 60.h,
              left: 0,
              right: 0,
              child: Text(
                "Outnest'e\nHoşgeldin!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                  height: 1.2,
                ),
              ),
            ),
            if (isOpen) ...[
              // BULUŞMA DOĞRULA (Sağ Üst)
              _buildLabel(
                bottom: 305.h,
                left: 232.w,
                text: 'Buluşma\nDoğrula',
                isRightSide: true,
              ),
              // FOTOĞRAF PAYLAŞ (Sol Orta)
              _buildLabel(
                bottom: 225.h,
                right: 232.w,
                text: 'Fotoğraf\nPaylaş',
                isRightSide: false,
              ),
              // BULUŞMA OLUŞTUR (Sağ Alt)
              _buildLabel(
                bottom: 155.h,
                left: 232.w,
                text: 'Buluşma\nOluştur',
                isRightSide: true,
              ),
            ],
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 60.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ActionButtonsSpeedDial(
                      isDialOpen: isDialOpen,
                      onCameraTap: () {},
                      onLocationTap: () {},
                      onQrTap: () {},
                      onIdeaTap: () {},
                      forceShowAllButtons: true,
                    ),
                    SizedBox(height: 16.h),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                      layoutBuilder: (currentChild, previousChildren) => Stack(
                        alignment: Alignment.center,
                        children: [
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      ),
                      child: Text(
                        dialEverClosed.value
                            ? 'devam etmek için kaydır'
                            : isOpen
                            ? 'butona tekrar basarak kapatabilirsin'
                            : 'başlamak için tıkla',
                        key: ValueKey(
                          dialEverClosed.value
                              ? 2
                              : isOpen
                              ? 1
                              : 0,
                        ),
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 13.sp,
                          color: AppColors.onBackgroundColor.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLabel({
    required double bottom,
    required String text,
    required bool isRightSide, // Etiket butonun sağında mı?
    double? left,
    double? right,
  }) {
    return Positioned(
      bottom: bottom,
      left: left,
      right: right,
      child: Column(
        crossAxisAlignment: isRightSide
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // OK İKONU
          Transform.rotate(
            angle: isRightSide ? -math.pi / 3 : math.pi / 3,
            child: Transform.flip(
              flipX: isRightSide,
              flipY: true,
              child: Icon(
                Symbols.switch_access_shortcut,
                color: AppColors.primaryColor,
                size: 24.sp,
              ),
            ),
          ),

          // METİN
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Text(
              text,
              textAlign: isRightSide ? TextAlign.center : TextAlign.center,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.onBackgroundColor,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sayfa 2-3-4 yapısı
  Widget _buildDualFeaturePage({
    required String topTitle,
    required String topDesc,
    required String topImagePath,
    required String bottomTitle,
    required String bottomDesc,
    required String bottomImagePath,
    String? bottomSecondImagePath,
  }) {
    return Column(
      children: [
        // ÜST
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Center(
              child: _buildFeatureRow(
                title: topTitle,
                description: topDesc,
                imagePath: topImagePath,
              ),
            ),
          ),
        ),

        // DIVIDER
        Divider(
          color: AppColors.dividerColor,
          height: 1,
          indent: 16.w,
          endIndent: 16.w,
        ),

        // ALT
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Center(
              child: _buildFeatureRow(
                title: bottomTitle,
                description: bottomDesc,
                imagePath: bottomImagePath,
                secondImagePath: bottomSecondImagePath,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureRow({
    required String title,
    required String description,
    required String imagePath,
    String? secondImagePath,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.tertiaryColor,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                description,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.onBackgroundColor,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        SizedBox(width: 28.w), // Metin ile görsel arasındaki boşluk
        SizedBox(
          width: 172.w,
          child: secondImagePath != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // İki görsel varsa her biri 172x90
                    _buildImageCard(imagePath, height: 90.h),
                    SizedBox(height: 12.h), // İki görsel arası boşluk
                    _buildImageCard(secondImagePath, height: 90.h),
                  ],
                )
              // Tek görsel varsa 172x172
              : _buildImageCard(imagePath, height: 172.h),
        ),
      ],
    );
  }

  Widget _buildImageCard(String path, {required double height}) {
    return Container(
      height: height,
      width: 172.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppColors.primaryColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          width: 172.w,
          height: height,
        ),
      ),
    );
  }
}
