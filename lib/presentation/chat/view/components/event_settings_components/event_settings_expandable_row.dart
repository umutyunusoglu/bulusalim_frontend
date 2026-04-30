import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EventSettingsExpandableRow extends StatelessWidget {
  const EventSettingsExpandableRow({
    super.key,
    required TextStyle labelStyle,
    required TextStyle subLabelStyle,
    required this.title,
    required this.subtitle,
    this.onTap,
  }) : _labelStyle = labelStyle,
       _subLabelStyle = subLabelStyle;

  final TextStyle _labelStyle;
  final TextStyle _subLabelStyle;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
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
            Icon(
              Icons.keyboard_arrow_right,
              color: Colors.black54,
              size: 22.sp,
            ), // Aşağı bakan oku sağa bakan ok ile değiştirdim, Bottom Sheet açılacağı için daha doğru bir yönlendirme oluyor
          ],
        ),
      ),
    );
  }
}
