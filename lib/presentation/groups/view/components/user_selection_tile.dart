import 'package:flutter/material.dart';
import 'package:outnest/presentation/groups/view/new_group_page.dart';

class UserSelectionTile extends StatelessWidget {
  const UserSelectionTile({
    super.key,
    required this.user,
    required this.onToggle,
  });
  final SelectableUser user;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: user.avatarUrl.isNotEmpty
                ? NetworkImage(user.avatarUrl)
                : null,
            child: user.avatarUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              user.username,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'ekle',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
