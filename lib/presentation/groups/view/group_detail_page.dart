import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/presentation/groups/view/groups_page.dart';
import 'package:outnest/presentation/groups/view/new_group_page.dart'; // SelectableUser için

class GroupDetailPage extends StatefulWidget {
  const GroupDetailPage({super.key, required this.group});
  final GroupModel group;

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final UserRepository _userRepository = GetIt.I<UserRepository>();

  // Tüm takip edilen kişileri tutacağımız ana liste
  List<SelectableUser> _allFollowees = [];
  bool _isLoading = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchRealFollowees();
  }

  Future<void> _fetchRealFollowees() async {
    try {
      final currentUserId =
          GetIt.I<SessionService>().currentUser?.userID ?? 'defaultUserId';

      final realData = await _userRepository.getFollowees(currentUserId);

      final mappedUsers = realData.map((followee) {
        return SelectableUser(
          id: followee.userID,
          username: followee.username,
          avatarUrl: followee.profileImageUrl,
          isAdded: false,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _allFollowees = mappedUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Kullanıcılar çekilirken hata oluştu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final unselectedUsers = _allFollowees.where((followee) {
      return !widget.group.members.any((member) => member.id == followee.id);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kümeler',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Üstteki Bilgi Metni
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                'İnsanları kümelere eklediğinde veya çıkardığında onlara bildirim gitmez.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),

          // 2. Tıklanabilir Küme Satırı
          SliverToBoxAdapter(
            child: InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bubble_chart_outlined,
                      color: Colors.blue,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.group.name,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          widget.group.memberCount.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _isExpanded ? Icons.expand_more : Icons.chevron_right,
                          color: Colors.black,
                          size: 28,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Küme İçindeki Üyeler
          if (_isExpanded)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final user = widget.group.members[index];

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFF2F2F7),
                      backgroundImage: user.avatarUrl.isNotEmpty
                          ? NetworkImage(user.avatarUrl)
                          : null,
                      child: user.avatarUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 20,
                            )
                          : null,
                    ),
                    title: Text(
                      user.username,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    // KÜMEDEN ÇIKAR BUTONU
                    trailing: GestureDetector(
                      onTap: () {
                        setState(() {
                          widget.group.members.removeAt(index);
                          widget.group.memberCount =
                              widget.group.members.length;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Text(
                          'kümeden çıkar',
                          style: TextStyle(
                            color: Color(0xFF003D6B),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: widget.group.members.length,
              ),
            ),

          // 4.  DİĞER KİŞİLER başlığı
          const SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 32),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'DİĞER KİŞİLER',
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Divider(height: 1, color: Color(0xFFE5E5EA)),
              ],
            ),
          ),

          // 5. Kümede Olmayan Takip Edilenler Listesi
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.tertiaryColor,
                  ),
                ),
              ),
            )
          else if (unselectedUsers.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'Eklenecek kimse kalmadı.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final user = unselectedUsers[index];

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: user.avatarUrl.isNotEmpty
                          ? NetworkImage(user.avatarUrl)
                          : null,
                      child: user.avatarUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                    title: Text(
                      user.username,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    // EKLE BUTONU
                    trailing: GestureDetector(
                      onTap: () {
                        setState(() {
                          widget.group.members.add(user);
                          widget.group.memberCount =
                              widget.group.members.length;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(
                            20,
                          ),
                        ),
                        child: const Text(
                          'kümeye ekle',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: unselectedUsers.length,
              ),
            ),

          // Listenin en altına kaydırma payı
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
