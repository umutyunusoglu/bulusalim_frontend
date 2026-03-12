import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';

class MapPeopleFilter extends StatefulWidget {
  const MapPeopleFilter({
    required this.options,
    required this.initial,
    required this.onChanged,
    super.key,
  });
  final List<String> options;
  final String initial;
  final void Function(String) onChanged;

  @override
  State<MapPeopleFilter> createState() => _MapPeopleFilterState();
}

class _MapPeopleFilterState extends State<MapPeopleFilter> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.options
        .indexOf(widget.initial)
        .clamp(0, widget.options.length - 1);
  }

  void _updateIndex(int delta) {
    setState(() {
      _index = (_index + delta + widget.options.length) % widget.options.length;
    });
    widget.onChanged(widget.options[_index]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 98.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: const Color(0xFFC6D0D9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildArrow(Icons.chevron_left, () => _updateIndex(-1)),
          Expanded(
            child: Center(
              child: Text(
                widget.options[_index],
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.tertiaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          _buildArrow(Icons.chevron_right, () => _updateIndex(1)),
        ],
      ),
    );
  }

  Widget _buildArrow(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 18.w,
        height: double.infinity,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16.sp,
          color: AppColors.tertiaryColor,
        ),
      ),
    );
  }
}
