import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/domain/services/security_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/presentation/settings/view/components/blocked_user_tile.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  final SecurityService _securityService = getIt<SecurityService>();
  final SessionService _sessionService = getIt<SessionService>();

  final TextEditingController _searchController = TextEditingController();
  // Arama filtresini reaktif tutmak için bir ValueNotifier ekliyoruz
  final ValueNotifier<String> _searchQuery = ValueNotifier('');

  @override
  void dispose() {
    _searchController.dispose();
    _searchQuery.dispose();
    super.dispose();
  }

  Future<void> _handleUnblock(String id) async {
    try {
      // Not: SessionService stream'i Firestore'u dinlediği için
      // unblock başarılı olduğunda liste otomatik olarak güncellenecektir.
      await _securityService.unblockUser(
        _sessionService.currentState.user!.userID,
        id,
      );
      if (mounted) {
        showInfoPopup(context, message: 'Kullanıcının engeli kaldırıldı.');
      }
    } catch (e) {
      if (mounted) {
        showErrorPopup(
          context,
          message: 'Kullanıcının engeli kaldırılırken hata oluştu',
        );
      }
    }
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
        title: Text(
          'Engellenen Kullanıcılar',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          children: [
            SizedBox(height: 10.h),
            // --- ARAMA ÇUBUĞU ---
            TextField(
              controller: _searchController,
              onChanged: (val) => _searchQuery.value = val,
              decoration: InputDecoration(
                hintText: 'Ara',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF2F4F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // --- REAKTİF LİSTE ---
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _sessionService.stateListenable,
                builder: (context, sessionState, _) {
                  // sessionState'den veriyi alırken null safety kontrolü
                  final allBlockedUsers = sessionState.blockedUsers;

                  return ValueListenableBuilder(
                    valueListenable: _searchQuery,
                    builder: (context, query, _) {
                      // Filtreleme işlemini burada yapıyoruz
                      final filteredUsers = allBlockedUsers.where((user) {
                        return user.username.toLowerCase().contains(
                          query.toLowerCase(),
                        );
                      }).toList();

                      if (filteredUsers.isEmpty) {
                        return Center(
                          child: Text(
                            query.isEmpty
                                ? 'Engellenen kullanıcı yok'
                                : 'Sonuç bulunamadı',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14.sp,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return BlockedUserTile(
                            username: user.username,
                            profileImageUrl: user.profileImageUrl,
                            onUnblockTap: () => _handleUnblock(user.userID),
                          );
                        },
                      );
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
