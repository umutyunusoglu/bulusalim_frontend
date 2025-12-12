import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileDumpTab extends StatelessWidget {
  const ProfileDumpTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Icon(
        Icons.lock_outline,
        size: 40.sp,
        color: theme.disabledColor,
      ),
    );
  }
}
