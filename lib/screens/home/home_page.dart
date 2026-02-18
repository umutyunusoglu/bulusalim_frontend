import 'package:cached_network_image/cached_network_image.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/components/custom_tab_bar.dart';
import 'package:outnest/components/header.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/core/utils/types/enums/feed_type.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/services/remote_config_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/screens/home/home_content_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class MockEvent {
  MockEvent({this.name, this.imageUrls});
  final String? name;
  final List<String>? imageUrls;
}
// -----------------------------------------------------

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<String> _tabs = ['Senlik', 'Arkadaşların', 'Okul'];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- 1. HİÇ BULUŞMA YOKSA (UYARI) ---
  void _showNoMeetingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Container(
          width: 361.w,
          height: 113.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Şu an bir buluşmada değilsin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryColor,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Gönderi paylaşabilmek için başlamış bir buluşmada bulunman gerekiyor. Gönderi paylaşmak için buluşma kur ya da başka kullanıcıların buluşmalarına katıl.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF8E8E93),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 2. BİRDEN FAZLA BULUŞMA VARSA (SEÇİM) ---
  void _showMultipleEventsSelectionDialog(
    BuildContext context,
    List<dynamic> activeEvents,
  ) {
    var selectedIndex = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Şu an hangi buluşmada olduğunu seç',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Carousel
                    SizedBox(
                      height: 100.h,
                      child: PageView.builder(
                        itemCount: activeEvents.length,
                        onPageChanged: (index) {
                          setState(() => selectedIndex = index);
                        },
                        itemBuilder: (context, index) {
                          final event = activeEvents[index] as EventEntity;

                          // Mock veriyi de gerçek veriyi de karşılayacak şekilde
                          final eventName =
                              event.name.toString() ?? 'Buluşma ${index + 1}';

                          final participants = event.participants;
                          // Mock listede veya gerçek entity'de imageUrls erişimi

                          final eventImage =
                              event.creator.profileImageUrl.isNotEmpty
                              ? event.creator.profileImageUrl
                              : FileService.defaultProfileImageUrl();

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 24.r,
                                backgroundImage: eventImage.startsWith('http')
                                    ? CachedNetworkImageProvider(
                                        fixEmulatorUrl(eventImage),
                                      )
                                    : AssetImage(eventImage),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                eventName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'SF Pro Display',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Dots Indicator
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(activeEvents.length, (index) {
                        return Container(
                          width: 5.w,
                          height: 5.w,
                          margin: EdgeInsets.symmetric(horizontal: 2.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selectedIndex == index
                                ? AppColors.primaryColor
                                : Colors.grey.shade300,
                          ),
                        );
                      }),
                    ),

                    SizedBox(height: 16.h),
                    Text(
                      'Birden fazla aktif buluşmada olduğun için hangi buluşmada olduğunu seçmelisin',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF8E8E93),
                      ),
                    ),
                    SizedBox(
                      height: 24.h,
                    ), // Butonlar ile yazı arasını biraz açtım
                    // --- GÜNCELLENEN BUTON ALANI (77x34 Hug) ---
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center, // Butonları ortala
                      children: [
                        // VAZGEÇ BUTONU
                        SizedBox(
                          width: 77.w,
                          height: 34.h,
                          child: TextButton(
                            onPressed: () => context.pop(),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFF2F2F7),
                              padding: EdgeInsets.zero, // Padding sıfırlandı
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.r),
                              ),
                            ),
                            child: Text(
                              'vazgeç',
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 12.sp,
                                fontWeight:
                                    FontWeight.w600, // Kalınlık artırıldı
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w), // Butonlar arası boşluk
                        // İLERLE BUTONU
                        SizedBox(
                          width: 77.w,
                          height: 34.h,
                          child: TextButton(
                            onPressed: () {
                              context
                                ..pop()
                                ..push(
                                  '/camera',
                                  extra: {'event': activeEvents[selectedIndex]},
                                );
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              padding: EdgeInsets.zero, // Padding sıfırlandı
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.r),
                              ),
                            ),
                            child: Text(
                              'ilerle',
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 12.sp,
                                fontWeight:
                                    FontWeight.w600, // Kalınlık artırıldı
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- 3. KAMERA YÖNLENDİRME MANTIĞI (TEST MODU) ---
  void _navigateToCamera() {
    // A) Kullanıcı verisini al
    final sessionService = getIt<SessionService>();
    final ongoingEvents = sessionService.currentState.ongoingEvents;

    if (ongoingEvents.isEmpty) {
      _showNoMeetingDialog(context);
    } else if (ongoingEvents.length == 1) {
      context.push('/camera', extra: {'event': ongoingEvents.first});
    } else {
      _showMultipleEventsSelectionDialog(context, ongoingEvents);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Header(
                  middleWidget: CustomTabBar(
                    currentIndex: _currentPage,
                    tabs: _tabs,
                    onTabSelected: (index) {
                      setState(() => _currentPage = index);
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
                SizedBox(height: 10.h),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    children: const [
                      HomeContentPage(feedType: FeedType.all),
                      HomeContentPage(feedType: FeedType.friendsOnly),
                      HomeContentPage(feedType: FeedType.university),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: 20.w,
              bottom: 100.h,
              child: GestureDetector(
                onTap: () async {
                  String url;
                  try {
                    url = await getIt<RemoteConfigService>().getValue<String>(
                      'feedback_url',
                    );
                  } catch (e) {
                    url = 'https://outnest.app/';
                  }

                  await url_launcher.launchUrl(
                    Uri.parse(url),
                  );
                },
                child: Container(
                  width: 56.w, // Alttaki butonun genişliği ile aynı
                  height: 90.w, // Alttaki butonun yüksekliği ile aynı
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.green, // Yuvarlağın arka plan rengi
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.question_mark,
                    size: 32.w, // İkon boyutunu biraz büyüttük
                    color: AppColors.backgroundColor,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16.w,
              bottom: 14.h,
              child: GestureDetector(
                onTap: _navigateToCamera,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/group103.png',
                    width: 62.w,
                    height: 90.w,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
