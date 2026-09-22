import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_strings.dart';
import '../models/match.dart';
import '../theme/app_colors.dart';

class DateSelectorBar extends StatefulWidget {
  final List<MatchDayItem> days;
  final String selectedDate;
  final ValueChanged<String> onDateSelected;

  const DateSelectorBar({
    super.key,
    required this.days,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<DateSelectorBar> createState() => _DateSelectorBarState();
}

class _DateSelectorBarState extends State<DateSelectorBar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected(animate: false));
  }

  @override
  void didUpdateWidget(DateSelectorBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate || oldWidget.days != widget.days) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected(animate: true));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelected({bool animate = true}) {
    if (!mounted || widget.days.isEmpty || !_scrollController.hasClients) return;
    final index = widget.days.indexWhere((d) => d.date == widget.selectedDate);
    if (index == -1) return;

    // Approximate width of each date pill + margin is ~76px
    const itemWidth = 76.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final targetOffset = (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
    final clampedOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    if (animate) {
      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(clampedOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColors.lightBackground;
    final unselectedPillBg = isDark ? AppColors.surface : AppColors.lightSurface;
    final borderSubtle = isDark ? AppColors.borderSubtle : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    if (widget.days.isEmpty) {
      return Container(
        height: 60,
        color: bg,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.emerald),
          ),
        ),
      );
    }

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      height: 68,
      color: bg,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        itemCount: widget.days.length,
        itemBuilder: (context, index) {
          final item = widget.days[index];
          final isSelected = item.date == widget.selectedDate;
          final isToday = item.date == todayStr;
          final dt = item.dateTime ?? DateTime.now();

          String dayName = DateFormat('EEE').format(dt).toUpperCase();
          if (isToday) dayName = AppStrings.get('day_today');

          return GestureDetector(
            onTap: () => widget.onDateSelected(item.date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.emerald : unselectedPillBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.emerald
                      : (isToday ? AppColors.emeraldDark.withValues(alpha: 0.7) : borderSubtle),
                  width: isToday && !isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected || isDark
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : (isToday ? AppColors.emerald : textMuted),
                      fontSize: 9,
                      fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d MMM').format(dt),
                    style: TextStyle(
                      color: isSelected ? Colors.black : textPrimary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${item.matches} ${item.matches == 1 ? AppStrings.get('match_suffix_single') : AppStrings.get('matches_suffix')}',
                    style: TextStyle(
                      color: isSelected ? Colors.black.withValues(alpha: 0.7) : textMuted,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
