import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  const CountdownTimer({
    required this.targetTime,
    super.key,
    this.style,
  });
  final DateTime targetTime;
  final TextStyle? style;

  @override
  _CountdownTimerState createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  String _countdownText = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _countdownText = _formatCountdown(widget.targetTime);
      });
    }
  }

  String _formatCountdown(DateTime startTime) {
    final now = DateTime.now();
    final difference = startTime.difference(now);

    // Negatif süre kontrolü (Örn: Etkinlik başladıysa)
    if (difference.isNegative) {
      return "Başladı";
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    List<String> parts = [];
    if (days > 0) parts.add("$days g.");
    if (hours > 0) parts.add("$hours sa.");
    // Sadece dakikalar kaldığında gösterim
    if (days == 0 && minutes > 0) parts.add("$minutes dk.");

    if (parts.isEmpty) return "Başlıyor";

    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final defaultStyle = theme.textTheme.labelLarge?.copyWith(
      fontFamily: 'Urbanist',
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
    );

    return Text(
      _countdownText,
      style: widget.style ?? defaultStyle,
    );
  }
}
