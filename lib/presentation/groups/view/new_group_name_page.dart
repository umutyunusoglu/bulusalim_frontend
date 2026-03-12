import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/repositories/group_repository.dart';
import 'package:outnest/presentation/groups/view/new_group_page.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';

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

  bool _isProcessing = false;

  void _createGroup() async {
    final groupName = _groupNameController.text.trim();

    // 1. Validasyon
    if (groupName.isEmpty) {
      showErrorPopup(context, message: 'Lütfen kümenize bir isim verin');

      return;
    }

    if (_isProcessing) return; // Çift tıklamayı engelle

    setState(() => _isProcessing = true);

    try {
      final groupRepo = GetIt.I<GroupRepository>();

      // 2. Mapping: SelectableUser -> CompactUserEntity
      final List<CompactUserEntity> initialMembers = widget.selectedUsers.map((
        u,
      ) {
        return CompactUserEntity(
          userID: u.id,
          username: u.username,
          profileImageUrl: u.avatarUrl,
          university: '',
          nameSurname: '',
          isPrivate: false,
          bio: '',
          accountType: null,
          communityData: null,
        );
      }).toList();

      // 3. Repository Call
      await groupRepo.createGroup(groupName, initialMembers);

      if (mounted) {
        // Başarılı! En başa (GroupsPage) dön.
        // popUntil kullanarak aradaki NewGroupPage'i de temizliyoruz.
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        showErrorPopup(
          context,
          message:
              'Yeni küme oluşturulurken hata oluştu. Lütfen tekrar deneyin',
        );
      }
    }
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
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: _isProcessing
                    ? null
                    : _createGroup, // İşlem varken tıklanmasın
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF218B3C),
                    shape: BoxShape.circle,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check, color: Colors.white, size: 16),
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
                              ? CachedNetworkImageProvider(user.avatarUrl)
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
