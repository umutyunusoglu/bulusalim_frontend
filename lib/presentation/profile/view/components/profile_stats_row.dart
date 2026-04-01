import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/presentation/profile/view/components/profile_stat_item.dart';
import 'package:outnest/presentation/profile/view/follows_page.dart';

class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({
    required this.profileUserID,
    required this.username,
    required this.numberOfEvents,
    required this.followerCount,
    required this.followingCount,
    super.key,
  });

  final String profileUserID;
  final String username;
  final int numberOfEvents;
  final int followerCount;
  final int followingCount;

  void _goToFollows(BuildContext context, int initialTabIndex) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => FollowsPage(
          profileUserID: profileUserID,
          username: username,
          followerCount: followerCount,
          followingCount: followingCount,
          initialTabIndex: initialTabIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 26),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ProfileStatItem(
            count: '$numberOfEvents',
            label: 'Buluşma',
          ),
          GestureDetector(
            onTap: () => _goToFollows(context, 0),
            child: ProfileStatItem(
              count: '$followerCount',
              label: 'Takipçi',
            ),
          ),
          GestureDetector(
            onTap: () => _goToFollows(context, 1),
            child: ProfileStatItem(
              count: '$followingCount',
              label: 'Takip',
            ),
          ),
        ],
      ),
    );
  }
}
