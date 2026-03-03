import 'package:flutter/material.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/presentation/groups/view/new_group_page.dart';

class NewGroupNamePage extends StatefulWidget {
  const NewGroupNamePage({super.key, required this.selectedUsers});
  final List<SelectableUser> selectedUsers;

  @override
  State<NewGroupNamePage> createState() => _NewGroupNamePageState();
}

class _NewGroupNamePageState extends State<NewGroupNamePage> {
  final TextEditingController _groupNameController = TextEditingController();

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  void _createGroup() {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir küme ismi girin.')),
      );
      return;
    }

    final result = {
      'name': groupName,
      'count': widget.selectedUsers.length,
      'members': List<SelectableUser>.from(widget.selectedUsers),
    };

    Navigator.pop(context, result);
  }

  void _handleBack() {
    Navigator.pop(context, widget.selectedUsers);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context, widget.selectedUsers);
            },
          ),
          title: const Text(
            'Kümene İsim Ver',
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
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: _createGroup,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF218B3C),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              TextField(
                controller: _groupNameController,
                textAlign: TextAlign.center,
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  hintText: 'örn. Liseden Çocuklar',
                  hintStyle: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
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
              const SizedBox(height: 32),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.selectedUsers.length,
                  itemBuilder: (context, index) {
                    final user = widget.selectedUsers[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: user.avatarUrl.isNotEmpty
                              ? NetworkImage(user.avatarUrl)
                              : null,
                          child: user.avatarUrl.isEmpty
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        title: Text(
                          user.username,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: GestureDetector(
                          onTap: () {
                            setState(() {
                              // Referans üzerinden ana listedeki durumu da güncelliyoruz
                              widget.selectedUsers[index].isAdded = false;
                              widget.selectedUsers.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'kümeden çıkar',
                              style: TextStyle(
                                color: Color(0xFF003D6B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
