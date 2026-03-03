import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/repositories/group_repository.dart';
import 'package:outnest/presentation/groups/view/group_detail_page.dart';
import 'package:outnest/presentation/groups/view/new_group_page.dart';

class GroupModel {
  GroupModel({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.members,
  });
  final String id;
  final String name;
  int memberCount;
  final List<SelectableUser> members;
}

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  List<GroupModel> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    setState(() => _isLoading = true);
    final groupRepo = GetIt.I<GroupRepository>();
    try {
      final groupNames = await groupRepo.getMyGroups();

      var fetchedGroups = <GroupModel>[];
      for (final name in groupNames) {
        final members = await groupRepo.getMembersOfMyGroup(name);
        fetchedGroups.add(
          GroupModel(
            id: name,
            name: name,
            memberCount: members.length,
            members: members
                .map(
                  (m) => SelectableUser(
                    id: m.userID,
                    username: m.username,
                    avatarUrl: m.profileImageUrl ?? '',
                    isAdded: true,
                  ),
                )
                .toList(),
          ),
        );
      }

      if (mounted) {
        setState(() {
          _groups = fetchedGroups;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Grupları çekerken hata: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _deleteGroup(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kümeyi Sil'),
        content: Text(
          '$name kümesini silmek istediğine emin misin? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sil',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await GetIt.I<GroupRepository>().deleteGroup(name);
        _fetchGroups(); // Silme sonrası listeyi yenile
      } catch (e) {
        debugPrint('Silme hatası: $e');
      }
    }
  }

  Future<void> _handleNewGroup() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewGroupPage()),
    );
    _fetchGroups();
  }

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        children: [
          // Yeni Küme Oluştur Butonu
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _handleNewGroup,
                  icon: const Icon(
                    Icons.add,
                    size: 14,
                    color: AppColors.tertiaryColor,
                  ),
                  label: const Text(
                    'Yeni Küme Oluştur',
                    style: TextStyle(
                      color: AppColors.tertiaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.tertiaryColor,
                    ),
                  )
                : _groups.isEmpty
                ? const Center(
                    child: Text(
                      'Henüz bir küme bulunmuyor.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchGroups,
                    child: ListView.builder(
                      itemCount: _groups.length,
                      itemBuilder: (context, index) {
                        final group = _groups[index];
                        return ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GroupDetailPage(group: group),
                              ),
                            ).then(
                              (_) => _fetchGroups(),
                            ); // Detaydan dönünce güncelliği kontrol et
                          },
                          onLongPress: () =>
                              _deleteGroup(group.name), // Uzun basınca silme
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: const Icon(
                            Icons.bubble_chart_outlined,
                            color: Colors.blue,
                            size: 26,
                          ),
                          title: Text(
                            group.name,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                group.memberCount.toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.black,
                                size: 24,
                              ),
                            ],
                          ),
                          shape: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
