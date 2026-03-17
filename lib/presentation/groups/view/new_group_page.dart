import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/presentation/groups/view/components/user_selection_tile.dart';
import 'package:outnest/presentation/groups/view/new_group_name_page.dart';

class SelectableUser {
  SelectableUser({
    required this.id,
    required this.username,
    this.avatarUrl = '',
    this.isAdded = false,
  });
  final String id;
  final String username;
  final String avatarUrl;
  bool isAdded;
}

class NewGroupPage extends StatefulWidget {
  const NewGroupPage({super.key});

  @override
  State<NewGroupPage> createState() => _NewGroupPageState();
}

class _NewGroupPageState extends State<NewGroupPage> {
  final UserRepository _userRepository = GetIt.I<UserRepository>();

  List<SelectableUser> followees = [];
  bool isLoading = true;

  String? _markedForRemovalId;

  @override
  void initState() {
    super.initState();
    _fetchRealFollowees();
  }

  Future<void> _fetchRealFollowees() async {
    try {
      final currentUserId =
          getIt<SessionService>().currentUser?.userID ?? 'defaultUserId';

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
          followees = mappedUsers;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      debugPrint('Kullanıcılar çekilirken hata oluştu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedUsers = followees.where((user) => user.isAdded).toList();
    final unselectedUsers = followees.where((user) => !user.isAdded).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Yeni Küme Oluştur',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        actions: [
          //  Yeşil Ok
          if (selectedUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: () async {
                  // 1. İsim verme sayfasına git ve sonucu bekle
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          NewGroupNamePage(selectedUsers: selectedUsers),
                    ),
                  );

                  // 2. Eğer result gelmişse (Boş geri dönülmemişse)
                  if (result != null && mounted) {
                    // DURUM A: Eğer result bir Map ise (Grup Başarıyla Kuruldu)
                    if (result is Map) {
                      // Veriyi bir üstteki GroupsPage'e gönder ve bu sayfayı da kapat
                      Navigator.pop(context, result);
                    }
                    // DURUM B: Eğer result bir List ise (Geri tuşuna basıldı, liste güncellendi)
                    else if (result is List<SelectableUser>) {
                      setState(() {
                        // Zaten referans üzerinden çalıştığımız için followees listesi güncel,
                        // sadece setState() çağırarak UI'ın kendini tazelemesini sağlıyoruz.
                        _markedForRemovalId =
                            null; // Varsa silme işaretini temizle
                      });
                    }
                  }
                },
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: const BoxDecoration(
                    color: Color(0xFF218B3C),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              cursorColor: Colors.black,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.grey,
                  size: 24,
                ),
                filled: true,
                fillColor: const Color(0xFFF2F2F7),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (selectedUsers.isNotEmpty) ...[
              SizedBox(
                height: 48,
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: selectedUsers.map((user) {
                        final isMarked = _markedForRemovalId == user.id;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isMarked) {
                                user.isAdded = false;
                                _markedForRemovalId = null;
                              } else {
                                _markedForRemovalId = user.id;
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFF7C9C1),
                                  width: 2,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.grey.shade300,
                                    backgroundImage: user.avatarUrl.isNotEmpty
                                        ? CachedNetworkImageProvider(
                                            user.avatarUrl,
                                          )
                                        : null,
                                    child: user.avatarUrl.isEmpty
                                        ? const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 20,
                                          )
                                        : null,
                                  ),
                                  if (isMarked)
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE5E5EA)),
              const SizedBox(height: 16),
            ],

            const Text(
              'İnsanları kümelere eklediğinde veya çıkardığında onlara bildirim gitmez.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.tertiaryColor,
                      ),
                    )
                  : unselectedUsers.isEmpty
                  ? const Center(
                      child: Text(
                        'Eklenecek kimse kalmadı.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: unselectedUsers.length,
                      itemBuilder: (context, index) {
                        final user = unselectedUsers[index];
                        return UserSelectionTile(
                          user: user,
                          onToggle: () {
                            setState(() {
                              user.isAdded = true;
                              _markedForRemovalId = null;
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
