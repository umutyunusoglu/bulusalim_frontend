import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/domain/session_state.dart';
import 'package:outnest/presentation/profile/view/components/user_list_item.dart';

class FollowsPage extends StatefulWidget {
  const FollowsPage({
    required this.profileUserID,
    required this.username,
    super.key,
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

  late List<CompactUserEntity> _followers = [];
  late List<CompactUserEntity> _followees = [];
  bool _isLoadingFollowers = false;
  bool _isLoadingFollowees = false;
  String? _followersError;
  String? _followeesError;

  @override
  void initState() {
    super.initState();

    isMe = widget.profileUserID == getIt<SessionService>().currentUser?.userID;

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    if (!isMe) {
      _loadFollowers();
      _loadFollowees();
    }
  }

  Future<void> _loadFollowers() async {
    setState(() {
      _isLoadingFollowers = true;
      _followersError = null;
    });

    try {
      final friendList = await getIt<UserRepository>().getFollowers(
        widget.profileUserID,
      );

      final mapped = friendList.map((friend) {
        return CompactUserEntity(
          userID: friend.userID,
          username: friend.username,
          profileImageUrl: friend.profileImageUrl,
          nameSurname: friend.username,
          university: null,
          isPrivate: null,
          bio: null,
          accountType: null,
          communityData: null,
        );
      }).toList();

      setState(() {
        _followers = mapped;
      });
    } catch (e) {
      setState(() {
        _followersError = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingFollowers = false;
      });
    }
  }

  Future<void> _loadFollowees() async {
    setState(() {
      _isLoadingFollowees = true;
      _followeesError = null;
    });

    try {
      final friendList = await getIt<UserRepository>().getFollowees(
        widget.profileUserID,
      );

      final mapped = friendList.map((friend) {
        return CompactUserEntity(
          userID: friend.userID,
          username: friend.username,
          profileImageUrl: friend.profileImageUrl,
          nameSurname: friend.username,
          university: null,
          isPrivate: null,
          bio: null,
          accountType: null,
          communityData: null,
        );
      }).toList();

      setState(() {
        _followees = mapped;
      });
    } catch (e) {
      setState(() {
        _followeesError = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingFollowees = false;
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
          icon: const Icon(Symbols.reply, color: Colors.black, size: 20),
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
            child: ValueListenableBuilder<SessionState>(
              valueListenable: getIt<SessionService>().stateListenable,
              builder: (context, session, child) {
                if (isMe) {
                  return _buildTabBar(
                    session.followers.length,
                    session.followees.length,
                  );
                } else {
                  final filteredFollowers = _applySessionRules(
                    _followers,
                    session,
                    true,
                  );

                  final filteredFollowees = _applySessionRules(
                    _followees,
                    session,
                    false,
                  );

                  return _buildTabBar(
                    filteredFollowers.length,
                    filteredFollowees.length,
                  );
                }
              },
            ),
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
      return ValueListenableBuilder<SessionState>(
        valueListenable: getIt<SessionService>().stateListenable,
        builder: (context, session, _) {
          final isLoading = isFollowerList
              ? _isLoadingFollowers
              : _isLoadingFollowees;

          final error = isFollowerList ? _followersError : _followeesError;

          final originalList = isFollowerList ? _followers : _followees;

          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          if (error != null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  "Veriler yüklenirken bir hata oluştu.\n$error",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red, fontSize: 13.sp),
                ),
              ),
            );
          }

          final filteredList = _applySessionRules(
            originalList,
            session,
            isFollowerList,
          );

          return _buildUserList(filteredList);
        },
      );
    }
  }

  List<CompactUserEntity> _applySessionRules(
    List<CompactUserEntity> list,
    SessionState session,
    bool isFollowerList,
  ) {
    final myUserId = session.user?.userID;

    return list.where((user) {
      if (user.userID == myUserId) {
        if (isFollowerList) {
          // Followers sekmesi → Me → X ilişkisi
          final iFollowProfileOwner = session.followees.any(
            (f) => f.userID == widget.profileUserID,
          );

          return iFollowProfileOwner;
        } else {
          // Followees sekmesi → X → Me ilişkisi
          final profileOwnerFollowsMe = session.followers.any(
            (f) => f.userID == widget.profileUserID,
          );

          return profileOwnerFollowsMe;
        }
      }

      return true;
    }).toList();
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
