import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/domain/session_state.dart';
import 'package:outnest/presentation/profile/view/components/user_list_item.dart';

class FollowsPage extends StatefulWidget {
  const FollowsPage({
    super.key,
    required this.profileUserID,
    required this.username,
    this.initialTabIndex = 0,
    this.followerCount = 0,
    this.followingCount = 0,
  });

  final String profileUserID;
  final String username;
  final int initialTabIndex;
  final int followerCount;
  final int followingCount;

  @override
  State<FollowsPage> createState() => _FollowsPageState();
}

class _FollowsPageState extends State<FollowsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool isMe;

  // Başkasının profili ise API isteklerini burada tutacağız
  Future<List<CompactUserEntity>>? _followersFuture;
  Future<List<CompactUserEntity>>? _followeesFuture;

  @override
  void initState() {
    super.initState();
    isMe = widget.profileUserID == getIt<SessionService>().currentUser?.userID;

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    // EĞER KENDİ PROFİLİMİZ DEĞİLSE API'DEN ÇEKİP ÇEVİRİYORUZ
    if (!isMe) {
      // 1. Takipçiler (Followers) listesini çek ve çevir
      _followersFuture = getIt<UserRepository>()
          .getFollowers(widget.profileUserID)
          .then((friendList) {
            return friendList.map((friend) {
              return CompactUserEntity(
                userID: friend.userID,
                username: friend.username,
                profileImageUrl: friend.profileImageUrl,
                nameSurname: friend
                    .username, // FriendEntity'de isim soyisim olmadığı için username atıyoruz
                university: null,
                isPrivate: null,
                bio: null,
              );
            }).toList();
          });

      // 2. Takip Edilenler (Followees) listesini çek ve çevir
      _followeesFuture = getIt<UserRepository>()
          .getFollowees(widget.profileUserID)
          .then((friendList) {
            return friendList.map((friend) {
              return CompactUserEntity(
                userID: friend.userID,
                username: friend.username,
                profileImageUrl: friend.profileImageUrl,
                nameSurname: friend.username,
                university: null,
                isPrivate: null,
                bio: null,
              );
            }).toList();
          });
    }
  }

  TabBar _buildTabBar(int followers, int followees) {
    return TabBar(
      controller: _tabController,
      indicatorColor: Colors.black,
      indicatorWeight: 2,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.grey.shade300,
      labelColor: Colors.black,
      unselectedLabelColor: const Color(0xFF8E8E93),
      labelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14.sp,
      ),
      tabs: [
        Tab(text: '$followers Takipçi'),
        Tab(text: '$followees Takip'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isMe ? 'Profilim' : widget.username,
          style: TextStyle(
            color: Colors.black,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.h),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: isMe
                ? ValueListenableBuilder<SessionState>(
                    valueListenable: getIt<SessionService>().stateListenable,
                    builder: (context, state, child) {
                      return _buildTabBar(
                        state.followers.length,
                        state.followees.length,
                      );
                    },
                  )
                : _buildTabBar(widget.followerCount, widget.followingCount),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListObserver(isFollowerList: true),
          _buildListObserver(isFollowerList: false),
        ],
      ),
    );
  }

  // Veri Kaynağını Seçen Widget
  Widget _buildListObserver({required bool isFollowerList}) {
    if (isMe) {
      // Kendi profilimizse SessionService'i dinle (Anlık güncellenir)
      return ValueListenableBuilder<SessionState>(
        valueListenable: getIt<SessionService>().stateListenable,
        builder: (context, state, _) {
          final list = isFollowerList ? state.followers : state.followees;
          return _buildUserList(list);
        },
      );
    } else {
      // Başkasının profiliyse initState'de oluşturduğumuz Future'ı kullan
      return FutureBuilder<List<CompactUserEntity>>(
        future: isFollowerList ? _followersFuture : _followeesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          // EĞER API'DEN YADA ÇEVİRİMDEN HATA GELİRSE EKRANDA GÖSTERECEK KISIM:
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  "Veriler yüklenirken bir hata oluştu.\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red, fontSize: 13.sp),
                ),
              ),
            );
          }

          return _buildUserList(snapshot.data ?? []);
        },
      );
    }
  }

  Widget _buildUserList(List<CompactUserEntity> users) {
    if (users.isEmpty) {
      return Center(
        child: Text(
          "Henüz kimse yok.",
          style: TextStyle(color: Colors.grey, fontSize: 14.sp),
        ),
      );
    }

    final sessionService = getIt<SessionService>();
    final myUserId = sessionService.currentUser?.userID;
    final myFollowees = sessionService.currentState.followees;

    var sortedUsers = <CompactUserEntity>[];

    // EĞER BAŞKASININ PROFİLİNE BAKIYORSAK ÖZEL SIRALAMA YAPIYORUZ
    if (!isMe && myUserId != null) {
      final meList = <CompactUserEntity>[];
      final followingList = <CompactUserEntity>[];
      final othersList = <CompactUserEntity>[];

      for (final user in users) {
        if (user.userID == myUserId) {
          // 1. Grup: BEN
          meList.add(user);
        } else if (myFollowees.any((f) => f.userID == user.userID)) {
          // 2. Grup: TAKİP ETTİKLERİM
          followingList.add(user);
        } else {
          // 3. Grup: DİĞER KİŞİLER
          othersList.add(user);
        }
      }

      // Grupları sırasıyla birleştiriyoruz (Ben -> Takip Ettiklerim -> Diğerleri)
      sortedUsers = [...meList, ...followingList, ...othersList];
    } else {
      // Kendi profilimse geldiği gibi göster
      sortedUsers = List.from(users);
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      itemCount: sortedUsers.length,
      separatorBuilder: (context, index) => SizedBox(height: 5.h),
      itemBuilder: (context, index) {
        final user = sortedUsers[index];

        // Bu satırdaki kişi giriş yapan BEN miyim?
        final isCurrentUser = user.userID == myUserId;
        // Bu kişiyi takip ediyor muyum?
        final amIFollowing = myFollowees.any((f) => f.userID == user.userID);

        return UserListItem(
          user: user,
          isMe: isMe,
          isFollowerList: _tabController.index == 0,
          isCurrentUser: isCurrentUser,
          amIFollowing: amIFollowing,
        );
      },
    );
  }
}
