import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileSectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  ProfileSectionHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get maxExtent => 80.h;

  @override
  double get minExtent => 80.h;

  @override
  bool shouldRebuild(ProfileSectionHeaderDelegate oldDelegate) => true;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          child,
        ],
      ),
    );
  }
}
