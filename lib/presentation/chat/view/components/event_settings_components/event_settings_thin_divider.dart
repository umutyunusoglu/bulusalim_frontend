import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EventSettingsThinDivider extends StatelessWidget {
  const EventSettingsThinDivider({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
      child: const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
    );
  }
}
