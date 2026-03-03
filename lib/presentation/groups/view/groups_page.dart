import 'package:flutter/material.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
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
  final List<GroupModel> _groups = [];

  Future<void> _handleNewGroup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewGroupPage()),
    );

    // Veri geldiğinde listeyi güncelle
    if (result != null && result is Map) {
      setState(() {
        _groups.insert(
          0, // Yeni kümeyi listenin en başına ekle
          GroupModel(
            id: DateTime.now().toString(),
            name: result['name'] as String,
            memberCount: result['count'] as int,
            members: result['members'] as List<SelectableUser>,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _handleNewGroup,
                  child: const Text(
                    '+ Yeni Küme Oluştur',
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
          const SizedBox(height: 16),
          Expanded(
            child: _groups.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bubble_chart_outlined,
                          size: 64,
                          color: Colors.black26,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Henüz bir küme bulunmuyor.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _groups.length,
                    itemBuilder: (context, index) {
                      final group = _groups[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GroupDetailPage(group: group),
                            ),
                          ).then((_) {
                            setState(() {});
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
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
                                    group.name,
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
                                      size: 28,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
