import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/services/security_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/screens/settings/blocked_user_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  final SecurityService _securityService = getIt<SecurityService>();
  final SessionService _sessionService = getIt<SessionService>();

  // HATA 1 ÇÖZÜMÜ: Late yerine boş liste ile başlatıyoruz.
  List<CompactUserEntity> _blockedUsers = [];
  List<CompactUserEntity> _filteredUsers = [];

  // HATA 2 ÇÖZÜMÜ: Yüklenme durumu için değişken.
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBlockedUsers();
  }

  // HATA 4 ÇÖZÜMÜ: Controller'ı dispose ediyoruz.
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Veri çekme işlemini ayrı bir asenkron fonksiyona aldık
  Future<void> _fetchBlockedUsers() async {
    final currentUser = _sessionService.currentUser;

    // HATA 3 ÇÖZÜMÜ: Kullanıcı null ise loading'i kapatıp boş liste gösteriyoruz.
    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final users = await _securityService.getBlockedUsers(currentUser.userID);

      if (mounted) {
        setState(() {
          _blockedUsers = users;
          _filteredUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Hata durumunda loading'i kapat
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // İstersen burada bir SnackBar ile hata mesajı gösterebilirsin
      }
    }
  }

  Future<void> _handleUnblock(String id) async {
    // Önce UI'dan silip kullanıcıya hızlı tepki veriyoruz (Optimistic Update)
    final deletedUserIndex = _blockedUsers.indexWhere((u) => u.userID == id);
    final deletedUser = _blockedUsers[deletedUserIndex];

    setState(() {
      _blockedUsers.removeWhere((user) => user.userID == id);
      _filterUsers(_searchController.text);
    });

    try {
      // API çağrısını yapıyoruz
      await _securityService.unblockUser(
        _sessionService.currentUser!.userID,
        id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kullanıcının engeli kaldırıldı."),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // HATA 5 ÇÖZÜMÜ: Eğer API hata verirse işlemi geri alıyoruz (Rollback)
      if (mounted) {
        setState(() {
          _blockedUsers.insert(deletedUserIndex, deletedUser);
          _filterUsers(_searchController.text);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata oluştu: $e")),
        );
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_blockedUsers);
      } else {
        _filteredUsers = _blockedUsers
            .where(
              (user) =>
                  user.username.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Engellenen Kullanıcılar',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Yükleniyor göstergesi
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  // --- ARAMA ÇUBUĞU ---
                  TextField(
                    controller: _searchController,
                    onChanged: _filterUsers,
                    cursorColor: Colors.black,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 14.sp,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ara',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14.sp,
                        fontFamily: 'SF Pro Display',
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade500,
                        size: 20.sp,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF2F4F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.r),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.r),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // --- KULLANICI LİSTESİ ---
                  Expanded(
                    child: _filteredUsers.isEmpty
                        ? Center(
                            child: Text(
                              'Engellenen kullanıcı yok',
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                color: Colors.grey,
                                fontSize: 14.sp,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              return BlockedUserTile(
                                username: user.username,
                                profileImageUrl: user.profileImageUrl,
                                onUnblockTap: () => _handleUnblock(user.userID),
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
