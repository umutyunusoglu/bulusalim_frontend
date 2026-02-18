import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TabItem extends StatelessWidget {
  const TabItem({
    required this.label,
    required this.isSelected,
    required this.width,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool isSelected;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.tertiary;
    final passiveColor =
        theme.textTheme.bodyMedium?.color?.withOpacity(0.5) ?? Colors.grey;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Sf Pro Display',
              fontSize: 16.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? activeColor : passiveColor,
            ),
          ),
        ),
      ),
    );
  }
}
