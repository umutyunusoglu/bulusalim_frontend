import 'dart:math';
import 'package:bulusalim/core/utils/debug/android_image_url_fixer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MapProfileMarker extends StatefulWidget {
  const MapProfileMarker({
    required this.imageUrl,
    required this.onTap,
    super.key,
  });

  final String imageUrl;
  final VoidCallback onTap;

  @override
  State<MapProfileMarker> createState() => _MapProfileMarkerState();
}

class _MapProfileMarkerState extends State<MapProfileMarker> {
  late _MarkerColorPair _selectedColorPair;

  static final List<_MarkerColorPair> _colorPalette = [
    const _MarkerColorPair(
      outer: Color(0xFFC6D0D9),
      inner: Color(0xFF5B7A98),
    ), // Mavi-Gri
    const _MarkerColorPair(
      outer: Color(0xFFFFCCBC),
      inner: Color(0xFFFF7043),
    ), // Somon
    const _MarkerColorPair(
      outer: Color(0xFFC8E6C9),
      inner: Color(0xFF66BB6A),
    ), // Yeşil
    const _MarkerColorPair(
      outer: Color(0xFFFFF9C4),
      inner: Color(0xFFFDD835),
    ), // Sarı
    const _MarkerColorPair(
      outer: Color(0xFFE1BEE7),
      inner: Color(0xFFAB47BC),
    ), // Mor
  ];

  @override
  void initState() {
    super.initState();
    // Rastgele renk seçimi
    _selectedColorPair = _colorPalette[Random().nextInt(_colorPalette.length)];
  }

  @override
  Widget build(BuildContext context) {
    // --- BOYUT HESAPLAMALARI ---

    // 1. DIŞ ÇERÇEVE (Outer)
    final double outerDiameter = 40.w;

    // 2. İÇ FOTOĞRAF (Inner/Image)
    const rawImageSize = 24.615385;
    final innerDiameter = rawImageSize.w;

    // Radius hesaplamaları (Çap / 2)
    final innerRadius = innerDiameter / 2;

    return SizedBox(
      width: outerDiameter,
      height: outerDiameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Katman 1: Dış Renkli Halka ve Gölge
          Container(
            width: outerDiameter,
            height: outerDiameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _selectedColorPair.outer,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),

          // Katman 2: İç Halka Rengi
          Container(
            width: innerDiameter + 6.w,
            height: innerDiameter + 6.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _selectedColorPair.inner,
            ),
          ),

          // Katman 3: Profil Resmi ve Tıklama Alanı
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              child: CircleAvatar(
                radius: innerRadius,
                backgroundColor: _selectedColorPair
                    .inner, // Resim yüklenene kadar görünen renk
                backgroundImage: NetworkImage(fixEmulatorUrl(widget.imageUrl)),
                onBackgroundImageError: (_, __) => debugPrint('Avatar Error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkerColorPair {
  const _MarkerColorPair({required this.outer, required this.inner});
  final Color outer;
  final Color inner;
}
