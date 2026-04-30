import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';

class EventSettingsSwitchRow extends StatelessWidget {
  const EventSettingsSwitchRow({
    super.key,
    required TextStyle labelStyle,
    required TextStyle subLabelStyle,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  }) : _labelStyle = labelStyle,
       _subLabelStyle = subLabelStyle;

  final TextStyle _labelStyle;
  final TextStyle _subLabelStyle;
  final String title;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _labelStyle),
                SizedBox(height: 6.h),
                Text(subtitle, style: _subLabelStyle),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: AppColors.primaryColor,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
}
