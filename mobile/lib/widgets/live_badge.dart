import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LiveBadge extends StatefulWidget {
  final int? minute;
  final String status;

  const LiveBadge({
    super.key,
    this.minute,
    required this.status,
  });

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status.toUpperCase();

    if (status == 'LIVE' || status == 'IN_PLAY') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.liveRedBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.liveRed.withValues(alpha: 0.4), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _animation,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.liveRed,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              widget.minute != null ? "${widget.minute}'" : 'LIVE',
              style: const TextStyle(
                color: AppColors.liveRed,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'HT') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.amberBg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'HT',
          style: TextStyle(
            color: AppColors.amber,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (status == 'FULL_TIME' || status == 'FT') {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceLight : AppColors.lightSurfaceLight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'FT',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
