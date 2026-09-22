import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/match.dart';
import '../theme/app_colors.dart';
import 'live_badge.dart';

class MatchCard extends StatelessWidget {
  final MatchItem match;
  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.match,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surface : AppColors.lightSurface;
    final borderCol = match.isLive
        ? AppColors.liveRed.withValues(alpha: 0.3)
        : (isDark ? AppColors.borderSubtle : AppColors.lightBorder);
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final badgeBg = isDark ? AppColors.surfaceLight : AppColors.lightSurfaceLight;

    final homeScore = match.score.home;
    final awayScore = match.score.away;
    final hasScore = homeScore != null && awayScore != null;
    final isHomeWinning = hasScore && homeScore > awayScore;
    final isAwayWinning = hasScore && awayScore > homeScore;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderCol,
            width: 1,
          ),
          boxShadow: isDark
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Left Status / Kickoff Column
            SizedBox(
              width: 58,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (match.isLive)
                    LiveBadge(minute: match.liveMinute, status: match.status)
                  else if (match.isFinished)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'FT',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else if (match.kickoffAt != null)
                    Text(
                      DateFormat('HH:mm').format(match.kickoffAt!.toLocal()),
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Text(
                      '-:-',
                      style: TextStyle(color: textMuted, fontSize: 12),
                    ),
                  if (match.round != null && !match.isLive) ...[
                    const SizedBox(height: 3),
                    Text(
                      "R${match.round}",
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Container(
              height: 36,
              width: 1,
              color: isDark ? AppColors.borderSubtle : AppColors.lightBorder,
              margin: const EdgeInsets.only(right: 12),
            ),

            // Teams Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Home Team
                  Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceElevated : const Color(0xFFECFDF5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.border : AppColors.emerald.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          match.homeTeam.name.isNotEmpty ? match.homeTeam.name[0] : 'H',
                          style: const TextStyle(
                            color: AppColors.emerald,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          match.homeTeam.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isHomeWinning || match.isLive
                                ? textPrimary
                                : textSecondary,
                            fontSize: 13.5,
                            fontWeight: isHomeWinning ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  // Away Team
                  Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceElevated : const Color(0xFFECFDF5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.border : AppColors.emerald.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          match.awayTeam.name.isNotEmpty ? match.awayTeam.name[0] : 'A',
                          style: const TextStyle(
                            color: AppColors.emerald,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          match.awayTeam.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isAwayWinning || match.isLive
                                ? textPrimary
                                : textSecondary,
                            fontSize: 13.5,
                            fontWeight: isAwayWinning ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scores Column
            if (hasScore)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "$homeScore",
                    style: TextStyle(
                      color: match.isLive
                          ? AppColors.liveRed
                          : (isHomeWinning ? textPrimary : textSecondary),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    "$awayScore",
                    style: TextStyle(
                      color: match.isLive
                          ? AppColors.liveRed
                          : (isAwayWinning ? textPrimary : textSecondary),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              )
            else
              Icon(
                Icons.chevron_right,
                color: textMuted,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
