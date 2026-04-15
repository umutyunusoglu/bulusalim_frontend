import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/services/file_service.dart';

class SuggestedUsersCarousel extends StatelessWidget {
  const SuggestedUsersCarousel({required this.users, super.key});
  final List<CompactUserEntity> users;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.person_outline, color: Colors.grey, size: 16),
              SizedBox(width: 4),
              Text(
                'Önerilen Kullanıcılar',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: users.length,
            separatorBuilder: (context, index) => const SizedBox(width: 20),
            itemBuilder: (context, index) {
              final user = users[index];
              return _SuggestedUserItem(user: user);
            },
          ),
        ),
      ],
    );
  }
}

class _SuggestedUserItem extends StatelessWidget {
  const _SuggestedUserItem({required this.user});
  final CompactUserEntity user;

  @override
  Widget build(BuildContext context) {
    final raw = user.profileImageUrl;
    final hasUrl = raw.isNotEmpty && raw.startsWith('http');

    return GestureDetector(
      onTap: () async {
        FocusScope.of(context).unfocus();
        await context.push('/home/profile/${user.userID}');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: hasUrl
                ? CachedNetworkImageProvider(fixEmulatorUrl(raw))
                : AssetImage(FileService.defaultProfileImageUrl())
                      as ImageProvider,
            onBackgroundImageError: (_, _) =>
                debugPrint('Carousel Avatar Error'),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 50,
            child: Text(
              user.username,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
