import 'package:bulusalim/screens/settings/blocked_user_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  // --- MOCK DATA ---
  final List<Map<String, String>> _blockedUsers = [
    {
      'id': '1',
      'username': 'can.yildirim',
      'image': 'https://i.pravatar.cc/150?u=1',
    },
    {
      'id': '2',
      'username': 'oyku.aslann',
      'image': 'https://i.pravatar.cc/150?u=2',
    },
    {
      'id': '3',
      'username': 'asliiozturk',
      'image': 'https://i.pravatar.cc/150?u=3',
    },
    {
      'id': '4',
      'username': 'ardadogan123',
      'image': 'https://i.pravatar.cc/150?u=4',
    },
    {
      'id': '5',
      'username': 'umut.yunusoglu',
      'image': 'https://i.pravatar.cc/150?u=5',
    },
    {
      'id': '6',
      'username': 'merttyıldırmmm',
      'image': 'https://i.pravatar.cc/150?u=6',
    },
    {
      'id': '7',
      'username': 'emre_gur',
      'image': 'https://i.pravatar.cc/150?u=7',
    },
    {
      'id': '8',
      'username': 'meriiikoc',
      'image': 'https://i.pravatar.cc/150?u=8',
    },
  ];

  late List<Map<String, String>> _filteredUsers;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredUsers = _blockedUsers;
  }

  void _handleUnblock(String id) {
    setState(() {
      _blockedUsers.removeWhere((user) => user['id'] == id);
      _filterUsers(_searchController.text);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Kullanıcının engeli kaldırıldı."),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _blockedUsers;
      } else {
        _filteredUsers = _blockedUsers
            .where(
              (user) =>
                  user['username']!.toLowerCase().contains(query.toLowerCase()),
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
      body: Padding(
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

                // --- ARKA PLAN VE RENK ---
                filled: true,
                fillColor: const Color(
                  0xFFF2F4F7,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    30.r,
                  ),
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.r),
                  borderSide: BorderSide.none,
                ),
                disabledBorder: OutlineInputBorder(
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
                          username: user['username']!,
                          profileImageUrl: user['image']!,
                          onUnblockTap: () => _handleUnblock(user['id']!),
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
