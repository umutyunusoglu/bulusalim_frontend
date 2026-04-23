import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

class NetworkSvg extends StatefulWidget {
  const NetworkSvg({required this.url, this.width, this.height, super.key});
  final String url;
  final double? width;
  final double? height;

  @override
  State<NetworkSvg> createState() => _NetworkSvgState();
}

class _NetworkSvgState extends State<NetworkSvg> {
  String? _svgString;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(Uri.parse(widget.url));
      if (res.statusCode == 200) {
        final cleaned = _convertClassStylesToInline(res.body);

        // GÜVENLİK: İstek bitene kadar widget ekrandan kalkmış olabilir.
        if (mounted) {
          setState(() => _svgString = cleaned);
        }
      }
    } catch (e) {
      debugPrint('SVG Yükleme Hatası: $e');
    }
  }

  String _convertClassStylesToInline(String svg) {
    final styleMatch = RegExp(
      '<style[^>]*>(.*?)</style>',
      dotAll: true,
    ).firstMatch(svg);
    if (styleMatch == null) return svg;

    final classProps = <String, Map<String, String>>{};
    final classRegex = RegExp(r'\.([a-zA-Z0-9_-]+)\s*\{([^}]+)\}');

    for (final m in classRegex.allMatches(styleMatch.group(1)!)) {
      final props = <String, String>{};
      for (final prop in m.group(2)!.split(';')) {
        final parts = prop.trim().split(':');
        if (parts.length == 2) props[parts[0].trim()] = parts[1].trim();
      }
      classProps[m.group(1)!] = props;
    }

    var result = svg;
    classProps.forEach((cls, props) {
      result = result.replaceAllMapped(
        RegExp(
          r'<(\w+)([^>]*?)class="[^"]*\b' + cls + r'\b[^"]*"([^>]*?)(/?)>',
        ),
        (m) {
          String attrs = '';
          props.forEach((k, v) => attrs += ' $k="$v"');
          return '<${m.group(1)}${m.group(2)}$attrs${m.group(3)}${m.group(4)}>';
        },
      );
    });

    return result.replaceAll(
      RegExp('<style[^>]*>.*?</style>', dotAll: true),
      '',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_svgString == null) return const SizedBox.shrink();

    return SvgPicture.string(
      _svgString!,
      width: widget.width,
      height: widget.height,
    );
  }
}
