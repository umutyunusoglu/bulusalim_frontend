import 'package:bulusalim/components/login_button.dart';
import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:bulusalim/screens/home/post%20components/small_stacked_avatars.dart';
import 'package:bulusalim/screens/profile/profile_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- MOCK VERİLER ---
  final String _username = "elif_dogan";
  final String _fullName = "Elif Doğan";
  final String _bio = "İşletme okuyorum adım elif merhaba ";
  final String _school = "İstanbul Teknik Üniversitesi";
  final String _avatarUrl = "https://picsum.photos/seed/elif/400/400";
  final List<String> _badges = [
    "https://cdn-icons-png.flaticon.com/512/616/616490.png",
  ];

  // --- DURUM YÖNETİMİ ---
  final bool _isPrivateAccount = false;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.secondaryColor;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // 1. HEADER (Profil Bilgileri - Scroll ile kaybolur)
              SliverToBoxAdapter(
                child: _buildProfileHeader(context),
              ),

              // 2. TAB BAR (Sticky - Tepeye yapışır)
              SliverPersistentHeader(
                delegate: SectionHeaderDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: activeColor,
                    indicatorWeight: 2,
                    labelColor: activeColor,
                    unselectedLabelColor: Colors.grey.shade400,
                    indicatorSize: TabBarIndicatorSize.tab,
                    padding: EdgeInsets.zero,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.grid_view_rounded, size: 24),
                        height: 48,
                      ),
                      Tab(
                        icon: Icon(Icons.location_on_outlined, size: 24),
                        height: 48,
                      ),
                      Tab(
                        icon: Icon(Icons.assignment_ind_outlined, size: 24),
                        height: 48,
                      ),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPhotosTab(),
              _buildEventsTab(),
              _buildDumpTab(),
            ],
          ),
        ),
      ),
    );
  }

  // --- HEADER ALANI ---
  Widget _buildProfileHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 21.w, right: 16.w, top: 45, bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. PROFİL FOTOĞRAFI (Üstten 45vardı + Boşluk)
              Padding(
                padding: EdgeInsets.only(top: 25.h),
                child: ProfilePhoto(
                  profileImageUrl: _avatarUrl,
                  badgeUrls: _badges,
                ),
              ),

              SizedBox(width: 21.w),

              // 2. SAĞ TARAFTAKİ ALAN
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // İSİM SATIRI
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 19.h),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _fullName,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Urbanist',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20.sp,
                                      color: Colors.black,
                                      height: 1.0.sp,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      Text(
                                        _username,
                                        style: TextStyle(
                                          fontFamily: 'Urbanist',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12.sp,
                                          color: const Color(0xFF004B75),
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Icon(
                                        Icons.camera_alt_outlined,
                                        size: 16.sp,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Ayarlar İkonu
                        Icon(
                          Icons.category_outlined,
                          color: const Color(0xFF004B75),
                          size: 24.sp,
                        ),
                      ],
                    ),

                    SizedBox(height: 9.h),

                    // İSTATİSTİKLER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const ProfileStatItem(count: "47", label: "Etkinlik"),
                        ProfileStatItem(
                          count: _isFollowing ? "139" : "138",
                          label: "Takipçi",
                        ),
                        const ProfileStatItem(count: "125", label: "Takip"),
                      ],
                    ),

                    SizedBox(height: 13.h),

                    // BIO
                    Text(
                      _bio,
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // OKUL
                    Row(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 16.sp,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            _school,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Urbanist',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // --- BUTONLAR ---
          Row(
            children: [
              Expanded(
                child: LoginButton(
                  label: _isFollowing
                      ? "takip ediyorsun"
                      : (_isPrivateAccount ? "istek gönder" : "takip et"),
                  onPress: _toggleFollow,
                  height: 32.h,
                  width: 361,
                  borderRadius: 20.r,
                  borderWidth: 1.5,
                  backgroundColor: _isFollowing
                      ? Colors.white
                      : const Color(0xFFFE6348),
                  textColor: _isFollowing
                      ? const Color(0xFFFE6348)
                      : Colors.white,
                  borderColor: const Color(0xFFFE6348),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),

              if (_isFollowing) ...[
                SizedBox(width: 16.w),
                Container(
                  height: 32.h,
                  width: 78.w,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: IconButton(
                    icon: Center(
                      child: Icon(
                        Icons.campaign_outlined,
                        color: Colors.black87,
                        size: 18.sp,
                      ),
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ],
          ),

          SizedBox(height: 16.h),

          // TAKİP EDENLER
          _buildFollowedBySection(),
        ],
      ),
    );
  }

  // --- HELPER BİLEŞENLER ---

  Widget _buildFollowedBySection() {
    // Mock Data
    final avatars = [
      'https://picsum.photos/seed/1/100/100',
      'https://picsum.photos/seed/2/100/100',
      'https://picsum.photos/seed/3/100/100',
    ];

    return Row(
      children: [
        // SmallStackedAvatars Bileşeni
        SmallStackedAvatars(
          avatarUrls: avatars,
          size: 24.r,
          overlap: 9.r,
          borderWidth: 0.sp,
        ),

        SizedBox(width: 8.w),

        // Açıklama Metni
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'Urbanist',
                fontSize: 10.sp,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              children: const [
                TextSpan(
                  text: "durucetin, yarkinyoruk",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: " ve "),
                TextSpan(
                  text: "4 diğer kişi",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: " tarafından takip ediliyor."),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosTab() {
    return GridView.builder(
      padding: EdgeInsets.all(2.w),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: 15,
      itemBuilder: (context, index) => Image.network(
        'https://picsum.photos/seed/photo$index/400/400',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildEventsTab() {
    return ListView.builder(
      padding: EdgeInsets.only(top: 10.h, bottom: 20.h),
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        height: 120.h,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Center(child: Text("Etkinlik Kartı $index")),
      ),
    );
  }

  Widget _buildDumpTab() {
    return Center(
      child: Icon(Icons.lock_outline, size: 40.sp, color: Colors.grey),
    );
  }
}

// İSTATİSTİK BİLEŞENİ
class ProfileStatItem extends StatelessWidget {
  final String count;
  final String label;
  const ProfileStatItem({super.key, required this.count, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          count,
          style: TextStyle(
            fontFamily: 'Urbanist',
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF004B75),
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Urbanist',
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF004B75),
          ),
        ),
      ],
    );
  }
}

// TAB BAR DELEGATE (Temiz Tasarım)
class SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  SectionHeaderDelegate(this.tabBar);

  @override
  double get minExtent => 48; // TabBar Yüksekliği
  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(height: 1, color: Colors.grey.shade200), // İnce Alt Çizgi
          tabBar, // TabBar ve Mavi Indicator
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(SectionHeaderDelegate oldDelegate) => false;
}
